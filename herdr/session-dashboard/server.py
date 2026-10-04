"""Local, read-only session dashboard HTTP server."""

from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import unicodedata
from urllib.parse import unquote

try:
    from transcripts import get_messages, list_transcripts
except ImportError:  # Package import when used by tests or an embedding caller.
    from .transcripts import get_messages, list_transcripts


ROOT = Path(__file__).resolve().parent
PUBLIC = ROOT / "public"
SOCKET_PATH = os.environ.get("HERDR_SOCKET_PATH", str(Path.home() / ".config/herdr/herdr.sock"))
STATIC_FILES = {"/": ("index.html", "text/html; charset=utf-8"),
                "/index.html": ("index.html", "text/html; charset=utf-8"),
                "/styles.css": ("styles.css", "text/css; charset=utf-8"),
                "/app.js": ("app.js", "text/javascript; charset=utf-8")}
AGENT_NAMES = {"claude": "Claude", "codex": "Codex", "opencode": "OpenCode"}
_BAD_PERCENT = re.compile(r"%(?![0-9a-fA-F]{2})")
_MAX_JSON_RESPONSE_BYTES = 512 * 1024
_MAX_TERMINAL_PREVIEW_BYTES = 16 * 1024
_ANSI_CONTROL = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|[@-_])")
_PREVIEW_UNAVAILABLE = "端末表示を取得できません。"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _string(value) -> str:
    return value if isinstance(value, str) else ""


def _ipc(method: str, params: dict) -> dict:
    request_id = str(uuid.uuid4())
    request = json.dumps({"id": request_id, "method": method, "params": params}, separators=(",", ":")).encode() + b"\n"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(2.0)
        client.connect(SOCKET_PATH)
        client.sendall(request)
        data = bytearray()
        while b"\n" not in data and len(data) <= 4 *  1024 * 1024:
            chunk = client.recv(65536)
            if not chunk:
                break
            data.extend(chunk)
    if len(data) > 4 * 1024 * 1024:
        raise RuntimeError("Herdr の応答が大きすぎます")
    try:
        response = json.loads(bytes(data).split(b"\n", 1)[0])
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise RuntimeError("Herdr から不正な応答が返されました") from exc
    if not isinstance(response, dict) or response.get("id") != request_id:
        raise RuntimeError("Herdr 応答の ID が一致しません")
    if response.get("error"):
        raise RuntimeError(_error_text(response["error"]))
    if not isinstance(response.get("result"), dict):
        raise RuntimeError("Herdr 応答に result がありません")
    return response["result"]


def _error_text(error) -> str:
    if isinstance(error, dict):
        return _string(error.get("message")) or "Herdr IPC エラー"
    return _string(error) or "Herdr IPC エラー"


def _snapshot() -> dict:
    result = _ipc("session.snapshot", {})
    snapshot = result.get("snapshot")
    if not isinstance(snapshot, dict):
        raise RuntimeError("Herdr snapshot の形式が正しくありません")
    return snapshot


def _status(value: str) -> str:
    value = value.lower().replace("-", "_")
    if value in {"working", "running", "busy", "active"}:
        return "working"
    if value in {"blocked", "waiting", "needs_input", "awaiting_input"}:
        return "blocked"
    if value in {"idle", "ready"}:
        return "idle"
    return "unknown"


def _agent_source(value: str) -> str:
    normalized = value.strip().lower()
    if normalized.startswith("herdr:"):
        normalized = normalized[len("herdr:"):]
    aliases = {
        "claude code": "claude", "claude-code": "claude",
        "open code": "opencode", "open-code": "opencode",
    }
    normalized = aliases.get(normalized, normalized)
    if normalized in AGENT_NAMES:
        return normalized
    for source, name in AGENT_NAMES.items():
        if normalized == name.lower():
            return source
    return ""


def _timestamp_epoch(value: str) -> float:
    """Normalize ISO timestamps and numeric seconds/milliseconds for sorting."""
    text = value.strip()
    if not text:
        return 0.0
    try:
        numeric = float(text)
    except ValueError:
        try:
            parsed = datetime.fromisoformat(text[:-1] + "+00:00" if text.endswith("Z") else text)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.timestamp()
        except ValueError:
            return 0.0
    return numeric / 1000 if abs(numeric) >= 100_000_000_000 else numeric


def _terminal_preview_text(value: str) -> str:
    text = _ANSI_CONTROL.sub("", value).replace("\r\n", "\n").replace("\r", "\n")
    text = "".join(char for char in text if char in "\n\t" or unicodedata.category(char) not in {"Cc", "Cf"})
    encoded = text.encode("utf-8")[:_MAX_TERMINAL_PREVIEW_BYTES]
    return encoded.decode("utf-8", errors="ignore").strip()


def _records(snapshot: dict, transcripts: list[dict], *, snapshot_available: bool = True) -> list[dict]:
    workspaces = {item.get("workspace_id"): item for item in snapshot.get("workspaces", [])
                  if isinstance(item, dict) and isinstance(item.get("workspace_id"), str)}
    tabs = {item.get("tab_id"): item for item in snapshot.get("tabs", [])
            if isinstance(item, dict) and isinstance(item.get("tab_id"), str)}
    agents = [item for item in snapshot.get("agents", []) if isinstance(item, dict)]
    by_pane = {}
    for agent in agents:
        pane_id = _string(agent.get("pane_id"))
        if pane_id:
            by_pane[pane_id] = agent
    snapshot_panes = [item for item in snapshot.get("panes", []) if isinstance(item, dict)]
    panes = []
    included_panes = set()
    for pane in snapshot_panes:
        pane_id = _string(pane.get("pane_id"))
        if not pane_id or pane_id in included_panes:
            continue
        agent = by_pane.get(pane_id)
        if agent is None and not _agent_source(_string(pane.get("agent"))):
            continue
        panes.append(pane)
        included_panes.add(pane_id)
    panes.extend(agent for pane_id, agent in by_pane.items() if pane_id not in included_panes)
    live: list[dict] = []
    matched: set[tuple[str, str]] = set()
    for pane in panes:
        pane_id = _string(pane.get("pane_id"))
        if not pane_id:
            continue
        agent = by_pane.get(pane_id, {})
        workspace_id = _string(pane.get("workspace_id") or agent.get("workspace_id"))
        tab_id = _string(pane.get("tab_id") or agent.get("tab_id"))
        workspace = workspaces.get(workspace_id, {})
        tab = tabs.get(tab_id, {})
        name = _string(agent.get("agent") or pane.get("agent"))
        reference = agent.get("agent_session")
        if not isinstance(reference, dict):
            reference = {}
        source = _agent_source(_string(reference.get("source")))
        session_id = _string(reference.get("value"))
        reference_agent = _agent_source(_string(reference.get("agent")))
        pane_agent = _agent_source(name)
        if (reference.get("kind") != "id" or source not in AGENT_NAMES or not session_id
                or (reference_agent and reference_agent != source)
                or (pane_agent and pane_agent != source)):
            source, session_id = "", ""
        else:
            matched.add((source, session_id))
        history = next((item for item in transcripts if item.get("source") == source and item.get("session_id") == session_id), {}) if source else {}
        title = (_string(history.get("title")) or _string(agent.get("terminal_title_stripped"))
                 or _string(agent.get("terminal_title")) or _string(tab.get("title"))
                 or _string(agent.get("title")))
        live.append({
            "key": f"pane:{pane_id}", "agent": AGENT_NAMES.get(name.lower(), name or "不明"),
            "status": _status(_string(agent.get("agent_status") or pane.get("agent_status"))),
            "workspace_id": workspace_id, "workspace_label": _string(workspace.get("label") or workspace.get("name") or workspace_id),
            "tab_id": tab_id, "pane_id": pane_id,
            "title": title,
            "cwd": _string(agent.get("cwd") or pane.get("foreground_cwd") or pane.get("cwd")),
            "updated_at": _string(history.get("updated_at")), "active": True,
            "source": source or "herdr", "status_source": "Herdr agent_status" if _status(_string(agent.get("agent_status") or pane.get("agent_status"))) != "unknown" else "状態未観測",
            "session_id": session_id,
        })
    historical = []
    for item in transcripts:
        if not isinstance(item, dict):
            continue
        source, session_id = _string(item.get("source")), _string(item.get("session_id"))
        if not source or not session_id or (source, session_id) in matched:
            continue
        historical.append({
            "key": f"history:{source}:{session_id}", "agent": AGENT_NAMES.get(source, source),
            "status": "not_active" if snapshot_available else "unknown",
            "workspace_id": "", "workspace_label": _string(item.get("cwd")) or "ワークスペース不明",
            "tab_id": "", "pane_id": "", "title": _string(item.get("title")), "cwd": _string(item.get("cwd")),
            "updated_at": _string(item.get("updated_at")), "active": False, "source": source,
            "status_source": ("Herdr に稼働ペインなし（終了は未確認）" if snapshot_available
                              else "状態不明（Herdr snapshot 取得失敗）"),
            "session_id": session_id,
        })
    priority = {"blocked": 0, "idle": 1, "working": 2, "unknown": 3}
    live.sort(key=lambda row: (priority[row["status"]], row["workspace_label"].lower(), row["pane_id"]))
    historical.sort(key=lambda row: _timestamp_epoch(row["updated_at"]), reverse=True)
    return live + historical


def _pane_is_current(row: dict) -> bool:
    snapshot = _snapshot()
    panes = snapshot.get("panes", [])
    if not isinstance(panes, list):
        return False
    pane = next((item for item in panes if isinstance(item, dict)
                 and item.get("pane_id") == row.get("pane_id")), None)
    if pane is None:
        return False

    agents = snapshot.get("agents", [])
    agent = next((item for item in agents if isinstance(item, dict)
                  and item.get("pane_id") == row.get("pane_id")), {}) if isinstance(agents, list) else {}
    agent_name = _string(agent.get("agent") or pane.get("agent"))
    listed_agent = _string(row.get("agent"))
    current_identity = _agent_source(agent_name) or agent_name.strip().lower()
    listed_identity = _agent_source(listed_agent) or listed_agent.strip().lower()
    if current_identity != listed_identity:
        return False

    reference = agent.get("agent_session")
    reference = reference if isinstance(reference, dict) else {}
    source = _agent_source(_string(reference.get("source")))
    kind = _string(reference.get("kind"))
    value = _string(reference.get("value"))
    expected_session_id = _string(row.get("session_id"))
    if expected_session_id:
        return kind == "id" and source == row.get("source") and value == expected_session_id
    # An ID-less row is still eligible for a preview only while the fresh
    # snapshot has no usable native ID for this agent.
    return not (kind == "id" and source in AGENT_NAMES and value)


def _read_terminal_preview(pane_id: str) -> str:
    result = _ipc("pane.read", {"pane_id": pane_id, "source": "recent", "format": "text", "lines": 60})
    read = result.get("read")
    text = _string(read.get("text")) if isinstance(read, dict) else ""
    return _terminal_preview_text(text)


def _sessions_payload() -> dict:
    errors = []
    snapshot_available = True
    try:
        history = list_transcripts(limit=150)
    except Exception as exc:
        history = []
        errors.append(f"履歴を取得できません: {exc}")
    try:
        snapshot = _snapshot()
    except Exception as exc:
        snapshot = {}
        snapshot_available = False
        errors.append(f"Herdr の状態を取得できません: {exc}")
    payload = {"sessions": _records(snapshot, history, snapshot_available=snapshot_available), "updated_at": _now()}
    if errors:
        payload["warning"] = " / ".join(errors)
    return payload


class DashboardHandler(BaseHTTPRequestHandler):
    server_version = "SessionDashboard/1.0"
    sys_version = ""

    def _send(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, status: int, data: dict) -> None:
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        if len(body) > _MAX_JSON_RESPONSE_BYTES:
            status = 500
            body = json.dumps({"error": "応答サイズが上限を超えました"}, ensure_ascii=False).encode("utf-8")
        self._send(status, body, "application/json; charset=utf-8")

    def _valid_host(self) -> bool:
        host = self.headers.get("Host", "")
        port = getattr(self.server, "server_port", 0)
        return host in {f"localhost:{port}", f"127.0.0.1:{port}"}

    def _security_error(self):
        if not self._valid_host():
            self._json(400, {"error": "許可されていない Host です"})
            return True
        return False

    def do_GET(self):
        if self._security_error():
            return
        if self.path == "/api/sessions":
            self._json(200, _sessions_payload())
            return
        prefix, suffix = "/api/sessions/", "/messages"
        if self.path.startswith(prefix) and self.path.endswith(suffix):
            encoded = self.path[len(prefix):-len(suffix)]
            if not encoded or "/" in encoded or _BAD_PERCENT.search(encoded):
                self._json(400, {"error": "セッションキーが不正です"})
                return
            try:
                key = unquote(encoded, encoding="utf-8", errors="strict")
            except (UnicodeDecodeError, ValueError):
                self._json(400, {"error": "セッションキーが不正です"})
                return
            sessions = _sessions_payload()
            row = next((item for item in sessions["sessions"] if item["key"] == key), None)
            if row is None:
                self._json(404, {"messages": [], "error": "セッションが見つかりません。"})
                return
            if row["session_id"] and row["source"] in AGENT_NAMES:
                try:
                    messages = get_messages(row["source"], row["session_id"], limit=80)
                except Exception:
                    messages = []
                if messages:
                    self._json(200, {"messages": messages, "truncated": len(messages) >= 80})
                    return
            if not row["active"] or not row["pane_id"]:
                self._json(200, {"messages": [], "error": "このセッションには表示できる会話がありません。"})
                return
            try:
                if not _pane_is_current(row):
                    self._json(200, {"messages": [], "error": "対象セッションの情報が更新されました。再読み込みしてください。"})
                    return
                preview = _read_terminal_preview(row["pane_id"])
            except Exception:
                preview = ""
            if not preview:
                self._json(200, {"messages": [], "error": _PREVIEW_UNAVAILABLE})
                return
            self._json(200, {"messages": [{"role": "terminal", "text": preview, "timestamp": ""}], "preview": True})
            return
        static = STATIC_FILES.get(self.path)
        if static:
            filename, content_type = static
            try:
                body = (PUBLIC / filename).read_bytes()
            except OSError:
                self._json(404, {"error": "ファイルが見つかりません"})
                return
            self._send(200, body, content_type)
            return
        self._json(404, {"error": "見つかりません"})

    def do_POST(self):
        if self._security_error():
            return
        if self.path != "/api/focus":
            self._json(404, {"ok": False, "error": "見つかりません"})
            return
        origin = self.headers.get("Origin", "")
        expected_origin = f"http://{self.headers.get('Host', '')}"
        if origin != expected_origin or self.headers.get("X-Session-Dashboard") != "1":
            self._json(403, {"ok": False, "error": "リクエスト元を確認できません"})
            return
        if self.headers.get_content_type() != "application/json":
            self._json(415, {"ok": False, "error": "Content-Type は application/json が必要です"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 16_384:
                raise ValueError
            body = json.loads(self.rfile.read(length))
        except (ValueError, json.JSONDecodeError, UnicodeDecodeError):
            self._json(400, {"ok": False, "error": "JSON リクエストが不正です"})
            return
        pane_id = _string(body.get("pane_id")) if isinstance(body, dict) else ""
        if not pane_id:
            self._json(400, {"ok": False, "error": "pane_id が必要です"})
            return
        try:
            snapshot = _snapshot()
        except Exception as exc:
            self._json(503, {"ok": False, "error": f"Herdr の状態を取得できません: {exc}"})
            return
        panes = snapshot.get("panes", [])
        panes = panes if isinstance(panes, list) else []
        valid = any(isinstance(item, dict) and item.get("pane_id") == pane_id for item in panes)
        if not valid:
            self._json(404, {"ok": False, "error": "対象の端末ペインは現在利用できません"})
            return
        try:
            _ipc("pane.focus", {"pane_id": pane_id})
        except Exception as exc:
            self._json(502, {"ok": False, "error": f"ペインへ移動できません: {exc}"})
            return
        app = os.environ.get("HERDR_DASHBOARD_TERMINAL_APP", "Ghostty")
        try:
            subprocess.run(["open", "-a", app], check=True, timeout=5, capture_output=True, text=True)
        except (OSError, subprocess.SubprocessError) as exc:
            self._json(502, {"ok": False, "pane_focused": True, "error": f"ペインには移動しましたが、端末アプリを前面にできません: {exc}"})
            return
        self._json(200, {"ok": True})

    def log_message(self, format, *args):
        pass


class LocalHTTPServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="ローカルの Session Dashboard")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("port は 1〜65535 で指定してください")
    server = LocalHTTPServer(("127.0.0.1", args.port), DashboardHandler)
    try:
        print(f"Session Dashboard: http://127.0.0.1:{server.server_port}")
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
