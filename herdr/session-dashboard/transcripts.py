"""Read-only transcript adapters for Claude Code, Codex, and OpenCode."""

from __future__ import annotations

import json
import os
import sqlite3
import stat
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import quote


_MAX_INDEX_FILES = 1000
_MAX_INDEX_BYTES = 16 * 1024 * 1024
_MAX_INDEX_SECONDS = 2.0
_MAX_METADATA_BYTES = 64 * 1024
_MAX_MESSAGE_BYTES = 8 * 1024 * 1024
_MAX_LIMIT = 500
_MAX_LINE_BYTES = 1024 * 1024
_MAX_MESSAGES = 80
_MAX_MESSAGE_TEXT_BYTES = 8 * 1024
_MAX_MESSAGES_JSON_BYTES = 256 * 1024
_MAX_OPENCODE_ROWS = 80
_INDEX_CACHE_TTL = 3.0
_SOURCE_ORDER = ("claude", "codex", "opencode")
_SOURCES = frozenset(_SOURCE_ORDER)
_INDEX_CACHE_LOCK = threading.Lock()
_INDEX_CACHE: tuple[tuple[str, ...], float, list[dict[str, Any]]] | None = None


def _limit(value: Any, default: int) -> int:
    try:
        value = int(value)
    except (TypeError, ValueError, OverflowError):
        value = default
    return max(0, min(value, _MAX_LIMIT))


def _regular_file(path: Path) -> os.stat_result | None:
    try:
        info = path.lstat()
        return info if stat.S_ISREG(info.st_mode) else None
    except (OSError, ValueError):
        return None


def _directories(path: Path) -> list[Path]:
    try:
        info = path.lstat()
        if not stat.S_ISDIR(info.st_mode):
            return []
        with os.scandir(path) as entries:
            return [Path(entry.path) for entry in entries if entry.is_dir(follow_symlinks=False)]
    except OSError:
        return []


def _json_objects(path: Path, max_bytes: int, *, tail: bool = False):
    info = _regular_file(path)
    if info is None or info.st_size <= 0:
        return
    try:
        with path.open("rb") as stream:
            remaining = min(info.st_size, max_bytes)
            if tail and info.st_size > max_bytes:
                stream.seek(info.st_size - max_bytes)
                discarded = stream.readline()  # Discard a possibly partial first record.
                remaining -= len(discarded)
            while remaining > 0:
                line = stream.readline(min(_MAX_LINE_BYTES + 1, remaining + 1))
                if not line:
                    break
                consumed = len(line)
                remaining -= min(consumed, remaining)
                if consumed > _MAX_LINE_BYTES:
                    if line[-1:] != b"\n" and remaining > 0:
                        discarded = stream.readline(remaining + 1)
                        remaining -= min(len(discarded), remaining)
                    continue
                try:
                    value = json.loads(line)
                except (UnicodeDecodeError, json.JSONDecodeError):
                    continue
                if isinstance(value, dict):
                    yield value
    except (OSError, ValueError):
        return


def _text_content(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text" and isinstance(block.get("text"), str):
            text = block["text"].strip()
            if text:
                parts.append(text)
    return "\n".join(parts)


def _timestamp(value: Any) -> str:
    return str(value) if isinstance(value, (str, int, float)) else ""


def _claude_projects() -> Path:
    return Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "projects"


def _codex_roots() -> list[Path]:
    root = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    return [root / "sessions", root / "sessions" / "archived_sessions", root / "archived_sessions"]


def _opencode_db() -> Path:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    return data_home / "opencode" / "opencode.db"


def _index_jsonl(source: str, path: Path, session_id: str) -> dict[str, Any] | None:
    info = _regular_file(path)
    if info is None:
        return None
    title = ""
    cwd = ""
    updated_at = ""
    started = time.monotonic()
    for record in _json_objects(path, min(info.st_size, _MAX_METADATA_BYTES)):
        if time.monotonic() - started > 0.15:
            break
        kind = record.get("type")
        if source == "claude":
            cwd = cwd or (record.get("cwd") if isinstance(record.get("cwd"), str) else "")
            updated_at = _timestamp(record.get("timestamp")) or updated_at
            message = record.get("message")
            if not title and kind == "user" and isinstance(message, dict):
                title = _text_content(message.get("content"))
        else:
            if kind == "session_meta":
                payload = record.get("payload")
                if isinstance(payload, dict):
                    cwd = payload.get("cwd") if isinstance(payload.get("cwd"), str) else cwd
                    meta_id = payload.get("id")
                    session_id = meta_id if isinstance(meta_id, str) else session_id
            if kind == "event_msg":
                payload = record.get("payload")
                if isinstance(payload, dict) and payload.get("type") == "user_message" and not title:
                    title = _text_content(payload.get("message"))
                updated_at = _timestamp(record.get("timestamp")) or updated_at
    if not updated_at:
        updated_at = str(int(info.st_mtime))
    return {"source": source, "session_id": session_id, "title": title[:500], "cwd": cwd, "updated_at": updated_at,
            "_path": str(path), "_mtime": info.st_mtime, "_size": info.st_size}


def _opencode_sessions() -> list[dict[str, Any]]:
    db_path = _opencode_db()
    info = _regular_file(db_path)
    if info is None:
        return []
    uri = "file:" + quote(str(db_path), safe="/") + "?mode=ro"
    try:
        connection = sqlite3.connect(uri, uri=True, timeout=0.2)
        try:
            connection.execute("PRAGMA query_only=ON")
            rows = connection.execute(
                "SELECT id, directory, title, time_updated FROM session ORDER BY time_updated DESC LIMIT ?",
                (_MAX_INDEX_FILES,),
            ).fetchall()
        finally:
            connection.close()
    except (sqlite3.Error, OSError, ValueError):
        return []
    sessions = []
    for sid, cwd, title, updated_at in rows:
        if not isinstance(sid, str) or not sid:
            continue
        sessions.append({"source": "opencode", "session_id": sid,
                         "title": title if isinstance(title, str) else "",
                         "cwd": cwd if isinstance(cwd, str) else "",
                         "updated_at": str(updated_at) if updated_at is not None else "",
                         "_db": str(db_path), "_mtime": info.st_mtime, "_size": info.st_size})
    return sessions


def _epoch_seconds(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        stamp = float(value)
        return stamp / 1000 if abs(stamp) >= 100_000_000_000 else stamp
    if not isinstance(value, str) or not value.strip():
        return None
    value = value.strip()
    try:
        stamp = float(value)
        return stamp / 1000 if abs(stamp) >= 100_000_000_000 else stamp
    except (ValueError, OverflowError):
        pass
    try:
        parsed = datetime.fromisoformat(value[:-1] + "+00:00" if value.endswith(("Z", "z")) else value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.timestamp()
    except (ValueError, OverflowError, OSError):
        return None


def _updated_order(item: dict[str, Any]) -> tuple[float, str]:
    updated = item.get("updated_at", "")
    normalized = _epoch_seconds(updated)
    return (normalized if normalized is not None else float(item.get("_mtime", 0)), str(updated))


def _cache_key() -> tuple[str, ...]:
    return tuple(str(path.expanduser().absolute()) for path in (_claude_projects(), *_codex_roots(), _opencode_db()))


def _cached_index() -> list[dict[str, Any]]:
    global _INDEX_CACHE
    key = _cache_key()
    now = time.monotonic()
    with _INDEX_CACHE_LOCK:
        if _INDEX_CACHE is not None and _INDEX_CACHE[0] == key and now < _INDEX_CACHE[1]:
            return [item.copy() for item in _INDEX_CACHE[2]]
        index = _build_index()
        _INDEX_CACHE = (key, time.monotonic() + _INDEX_CACHE_TTL, index)
        return [item.copy() for item in index]


def _build_index() -> list[dict[str, Any]]:
    started = time.monotonic()
    entries: dict[str, list[tuple[float, Path]]] = {source: [] for source in _SOURCE_ORDER}
    projects = _claude_projects()
    for project in _directories(projects):
        try:
            with os.scandir(project) as files:
                for entry in files:
                    if sum(map(len, entries.values())) >= _MAX_INDEX_FILES * 4 or time.monotonic() - started >= _MAX_INDEX_SECONDS:
                        break
                    if not entry.name.endswith(".jsonl") or not entry.is_file(follow_symlinks=False):
                        continue
                    path = Path(entry.path)
                    info = _regular_file(path)
                    if info is not None:
                        entries["claude"].append((info.st_mtime, path))
        except OSError:
            continue
    for root in _codex_roots():
        parents = [(root, 0)]
        while parents:
            if sum(map(len, entries.values())) >= _MAX_INDEX_FILES * 4 or time.monotonic() - started >= _MAX_INDEX_SECONDS:
                break
            parent, depth = parents.pop()
            if depth < 4:
                parents.extend((child, depth + 1) for child in _directories(parent))
            try:
                with os.scandir(parent) as files:
                    for entry in files:
                        if sum(map(len, entries.values())) >= _MAX_INDEX_FILES * 4 or time.monotonic() - started >= _MAX_INDEX_SECONDS:
                            break
                        if not entry.name.startswith("rollout-") or not entry.name.endswith(".jsonl") or not entry.is_file(follow_symlinks=False):
                            continue
                        path = Path(entry.path)
                        info = _regular_file(path)
                        if info is not None:
                            entries["codex"].append((info.st_mtime, path))
            except OSError:
                continue
    for source in ("claude", "codex"):
        entries[source].sort(key=lambda item: item[0], reverse=True)
        entries[source] = entries[source][:_MAX_INDEX_FILES]

    # Round-robin metadata reads prevent one transcript format from consuming
    # the entire byte/time budget before another source is considered.
    sessions = []
    bytes_seen = 0
    positions = {source: 0 for source in ("claude", "codex")}
    read_bytes = {source: 0 for source in positions}
    source_budget = _MAX_INDEX_BYTES // len(positions)
    while time.monotonic() - started < _MAX_INDEX_SECONDS and bytes_seen < _MAX_INDEX_BYTES:
        progressed = False
        for source in ("claude", "codex"):
            position = positions[source]
            if position >= len(entries[source]) or read_bytes[source] >= source_budget:
                continue
            mtime, path = entries[source][position]
            positions[source] += 1
            info = _regular_file(path)
            if info is None:
                continue
            charge = min(info.st_size, _MAX_METADATA_BYTES)
            if bytes_seen + charge > _MAX_INDEX_BYTES:
                continue
            item = _index_jsonl(source, path, path.stem)
            read_bytes[source] += charge
            bytes_seen += charge
            progressed = True
            if item:
                item["_mtime"] = mtime
                sessions.append(item)
        if not progressed:
            # Redistribute unused per-source byte allowance after that source
            # runs out of files, while retaining the global byte ceiling.
            remaining_sources = [s for s in positions if positions[s] < len(entries[s])]
            if not remaining_sources:
                break
            eligible = [s for s in remaining_sources if read_bytes[s] >= source_budget]
            if not eligible:
                break
            source_budget += max(1, (_MAX_INDEX_BYTES - bytes_seen) // len(eligible))
    sessions.extend(_opencode_sessions())
    sessions.sort(key=_updated_order, reverse=True)
    return sessions


def list_transcripts(limit: int = 150) -> list[dict]:
    """Return the most recently updated, safely indexed sessions."""
    count = _limit(limit, 150)
    if count == 0:
        return []
    indexed = _cached_index()
    by_source = {source: [] for source in _SOURCE_ORDER}
    for item in indexed:
        by_source[item["source"]].append(item)

    # Reserve an equal share for every available source, then refill unused
    # shares from the globally most recent remaining sessions.
    available = [source for source, items in by_source.items() if items]
    if not available:
        return []
    quota, extra = divmod(count, len(available))
    selected = []
    used = {source: 0 for source in available}
    for index, source in enumerate(available):
        take = min(len(by_source[source]), quota + (index < extra))
        selected.extend(by_source[source][:take])
        used[source] = take
    remaining = []
    for source in available:
        remaining.extend(by_source[source][used[source]:])
    remaining.sort(key=_updated_order, reverse=True)
    selected.extend(remaining[:count - len(selected)])
    selected.sort(key=_updated_order, reverse=True)
    result = []
    for item in selected[:count]:
        result.append({key: item.get(key, "") for key in ("source", "session_id", "title", "cwd", "updated_at")})
    return result


def _claude_messages(path: Path, limit: int) -> list[dict]:
    records = []
    for record in _json_objects(path, _MAX_MESSAGE_BYTES, tail=True):
        if record.get("type") not in ("user", "assistant") or record.get("isSidechain") or record.get("isMeta"):
            continue
        message = record.get("message")
        if not isinstance(message, dict):
            continue
        text = _text_content(message.get("content"))
        if text:
            records.append({"role": record["type"], "text": text, "timestamp": _timestamp(record.get("timestamp"))})
    return records[-limit:] if limit else []


def _codex_messages(path: Path, limit: int) -> list[dict]:
    records = list(_json_objects(path, _MAX_MESSAGE_BYTES, tail=True))
    events = []
    response = []
    for record in records:
        kind = record.get("type")
        payload = record.get("payload")
        if kind == "event_msg" and isinstance(payload, dict):
            role = {"user_message": "user", "agent_message": "assistant"}.get(payload.get("type"))
            text = _text_content(payload.get("message"))
            if role and text:
                events.append({"role": role, "text": text, "timestamp": _timestamp(record.get("timestamp"))})
        elif kind == "response_item" and isinstance(payload, dict) and payload.get("type") == "message":
            role = payload.get("role")
            if role not in ("user", "assistant"):
                continue
            content = payload.get("content")
            text = _text_content(content)
            if not text and isinstance(content, list):
                text = "\n".join(block["text"].strip() for block in content
                                  if isinstance(block, dict) and block.get("type") in ("input_text", "output_text")
                                  and isinstance(block.get("text"), str) and block["text"].strip())
            if text:
                response.append({"role": role, "text": text, "timestamp": _timestamp(record.get("timestamp"))})
    selected = events or response
    return selected[-limit:] if limit else []


def _truncate_text(text: str, max_bytes: int) -> str:
    encoded = text.encode("utf-8")
    if len(encoded) <= max_bytes:
        return text
    marker = "… [truncated]"
    marker_bytes = marker.encode("utf-8")
    if max_bytes <= len(marker_bytes):
        return marker if max_bytes == len(marker_bytes) else ""
    prefix = encoded[:max_bytes - len(marker_bytes)].decode("utf-8", errors="ignore")
    return prefix + marker


def _bounded_messages(messages: list[dict], limit: int) -> list[dict]:
    """Bound both message count and the UTF-8 JSON representation of results."""
    result: list[dict] = []
    # Prioritize the newest items if the total response budget is exhausted.
    for message in reversed(messages[-min(limit, _MAX_MESSAGES):]):
        role = message.get("role")
        if role not in ("user", "assistant"):
            continue
        text = message.get("text")
        if not isinstance(text, str) or not text:
            continue
        timestamp = message.get("timestamp")
        candidate = {"role": role, "text": _truncate_text(text, _MAX_MESSAGE_TEXT_BYTES),
                     "timestamp": timestamp[:128] if isinstance(timestamp, str) else ""}

        def encoded_size(item: dict) -> int:
            return len(json.dumps([*result, item], ensure_ascii=False).encode("utf-8"))

        if encoded_size(candidate) > _MAX_MESSAGES_JSON_BYTES:
            available = max(0, _MAX_MESSAGES_JSON_BYTES - len(json.dumps(result, ensure_ascii=False).encode("utf-8")))
            original = candidate["text"]
            low, high = 0, min(len(original.encode("utf-8")), available)
            best = None
            while low <= high:
                middle = (low + high) // 2
                trial = candidate.copy()
                trial["text"] = _truncate_text(original, middle)
                if encoded_size(trial) <= _MAX_MESSAGES_JSON_BYTES:
                    best = trial
                    low = middle + 1
                else:
                    high = middle - 1
            if best is None or not best["text"]:
                continue
            candidate = best
        result.append(candidate)
    result.reverse()
    return result


def _opencode_messages(db_path: Path, session_id: str, limit: int) -> list[dict]:
    uri = "file:" + quote(str(db_path), safe="/") + "?mode=ro"
    try:
        connection = sqlite3.connect(uri, uri=True, timeout=0.2)
        try:
            connection.execute("PRAGMA query_only=ON")
            rows = connection.execute(
                "SELECT CASE WHEN json_valid(message_data) THEN json_extract(message_data, '$.role') END AS role, "
                "CASE WHEN json_valid(message_data) THEN json_extract(message_data, '$.time.created') END AS created, "
                "CASE WHEN json_valid(part_data) THEN substr(json_extract(part_data, '$.text'), 1, ?) END AS text FROM ("
                "SELECT m.id AS message_id, m.data AS message_data, p.data AS part_data "
                "FROM message AS m "
                "JOIN part AS p ON p.message_id=m.id AND p.session_id=m.session_id "
                "WHERE m.session_id=? ORDER BY m.id DESC LIMIT ?"
                ") WHERE CASE WHEN json_valid(message_data) THEN json_extract(message_data, '$.role') END IN ('user','assistant') "
                "AND CASE WHEN json_valid(part_data) THEN json_extract(part_data, '$.type') END='text' "
                "ORDER BY message_id DESC", (_MAX_MESSAGE_TEXT_BYTES + 1, session_id, _MAX_OPENCODE_ROWS),
            ).fetchall()
        finally:
            connection.close()
    except (sqlite3.Error, OSError, ValueError):
        return []
    messages = []
    for role, created, text in reversed(rows):
        if role in ("user", "assistant") and isinstance(text, str) and text.strip():
            messages.append({"role": role, "text": text.strip(), "timestamp": _timestamp(created)})
    return _bounded_messages(messages[-limit:] if limit else [], limit)


def get_messages(source: str, session_id: str, limit: int = 80) -> list[dict]:
    """Return text messages only for a session present in the current safe index."""
    count = _limit(limit, 80)
    if not isinstance(source, str) or source not in _SOURCES or not isinstance(session_id, str) or not session_id or not count:
        return []
    count = min(count, _MAX_MESSAGES)
    matches = [item for item in _cached_index() if item.get("source") == source and item.get("session_id") == session_id]
    if not matches:
        return []
    item = matches[0]
    if source == "opencode":
        return _opencode_messages(Path(item["_db"]), session_id, count)
    path = Path(item["_path"])
    if _regular_file(path) is None:
        return []
    messages = _claude_messages(path, count) if source == "claude" else _codex_messages(path, count)
    return _bounded_messages(messages, count)
