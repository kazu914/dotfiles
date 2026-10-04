import json
import os
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import transcripts


class TranscriptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.claude = self.root / "claude"
        self.codex = self.root / "codex"
        self.data = self.root / "data"
        env = {
            "CLAUDE_CONFIG_DIR": str(self.claude),
            "CODEX_HOME": str(self.codex),
            "XDG_DATA_HOME": str(self.data),
        }
        self.patch = patch.dict(os.environ, env, clear=False)
        self.patch.start()
        (self.claude / "projects" / "project").mkdir(parents=True)
        (self.codex / "sessions" / "2026" / "01" / "01").mkdir(parents=True)

    def tearDown(self):
        self.patch.stop()
        self.temp.cleanup()

    @staticmethod
    def write_jsonl(path, records):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(json.dumps(record) + "\n" for record in records), encoding="utf-8")

    def test_claude_text_blocks_and_exclusions(self):
        path = self.claude / "projects" / "project" / "claude-id.jsonl"
        self.write_jsonl(path, [
            {"type": "user", "timestamp": "2026-01-01T00:00:00Z", "cwd": "/work", "message": {"content": "Question"}},
            {"type": "assistant", "message": {"content": [{"type": "text", "text": "Answer"}, {"type": "tool_use", "name": "secret"}, {"type": "thinking", "thinking": "hidden"}]}},
            {"type": "assistant", "isSidechain": True, "message": {"content": "hidden"}},
            {"type": "user", "isMeta": True, "message": {"content": "hidden"}},
        ])
        self.assertEqual(transcripts.list_transcripts()[0]["session_id"], "claude-id")
        self.assertEqual(transcripts.get_messages("claude", "claude-id"), [
            {"role": "user", "text": "Question", "timestamp": "2026-01-01T00:00:00Z"},
            {"role": "assistant", "text": "Answer", "timestamp": ""},
        ])

    def test_codex_event_messages_preferred_over_response_items(self):
        path = self.codex / "sessions" / "2026" / "01" / "01" / "rollout-sample.jsonl"
        self.write_jsonl(path, [
            {"type": "session_meta", "payload": {"id": "codex-id", "cwd": "/repo"}},
            {"type": "event_msg", "timestamp": "t1", "payload": {"type": "user_message", "message": "Hi"}},
            {"type": "response_item", "timestamp": "t1", "payload": {"type": "message", "role": "user", "content": [{"type": "input_text", "text": "Hi"}]}},
            {"type": "event_msg", "timestamp": "t2", "payload": {"type": "agent_message", "message": "Hello"}},
            {"type": "response_item", "payload": {"type": "function_call", "name": "hidden"}},
        ])
        self.assertEqual(transcripts.get_messages("codex", "codex-id"), [
            {"role": "user", "text": "Hi", "timestamp": "t1"},
            {"role": "assistant", "text": "Hello", "timestamp": "t2"},
        ])
        self.assertEqual(transcripts.get_messages("codex", "../other"), [])

    def test_codex_response_item_fallback_and_limit(self):
        path = self.codex / "sessions" / "rollout-fallback.jsonl"
        self.write_jsonl(path, [
            {"type": "response_item", "payload": {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "one"}]}},
            {"type": "response_item", "payload": {"type": "message", "role": "assistant", "content": [{"type": "output_text", "text": "two"}]}},
        ])
        self.assertEqual([m["text"] for m in transcripts.get_messages("codex", "rollout-fallback", 1)], ["two"])

    def test_opencode_read_only_text_parts(self):
        db = self.data / "opencode" / "opencode.db"
        db.parent.mkdir(parents=True)
        connection = sqlite3.connect(db)
        connection.executescript("CREATE TABLE session(id,directory,title,time_updated); CREATE TABLE message(id,session_id,data); CREATE TABLE part(message_id,session_id,data);")
        connection.execute("INSERT INTO session VALUES(?,?,?,?)", ("oc-id", "/repo", "Title", 10))
        connection.execute("INSERT INTO message VALUES(?,?,?)", ("m1", "oc-id", json.dumps({"role": "user", "time": {"created": 1}})))
        connection.execute("INSERT INTO part VALUES(?,?,?)", ("m1", "oc-id", json.dumps({"type": "text", "text": "Question"})))
        connection.execute("INSERT INTO message VALUES(?,?,?)", ("m2", "oc-id", json.dumps({"role": "assistant"})))
        connection.execute("INSERT INTO part VALUES(?,?,?)", ("m2", "oc-id", json.dumps({"type": "tool", "text": "hidden"})))
        connection.commit()
        connection.close()
        self.assertEqual(transcripts.list_transcripts()[0]["title"], "Title")
        self.assertEqual(transcripts.get_messages("opencode", "oc-id"), [
            {"role": "user", "text": "Question", "timestamp": "1"},
        ])
        self.assertEqual(transcripts.get_messages("opencode", "unknown"), [])

    def test_symlink_transcripts_are_ignored_and_limits_clamped(self):
        outside = self.root / "outside.jsonl"
        self.write_jsonl(outside, [{"type": "user", "message": {"content": "not indexed"}}])
        link = self.claude / "projects" / "project" / "linked.jsonl"
        link.symlink_to(outside)
        self.assertEqual(transcripts.list_transcripts(0), [])
        self.assertEqual(transcripts.list_transcripts(), [])
        self.assertEqual(transcripts.get_messages("invalid", "linked"), [])

    def test_database_errors_are_isolated(self):
        (self.data / "opencode").mkdir(parents=True)
        (self.data / "opencode" / "opencode.db").write_text("not sqlite", encoding="utf-8")
        self.assertEqual(transcripts.list_transcripts(), [])
        self.assertEqual(transcripts.get_messages("opencode", "id"), [])

    def test_list_transcripts_reserves_slots_for_each_available_source(self):
        for index in range(2):
            path = self.claude / "projects" / "project" / f"claude-{index}.jsonl"
            self.write_jsonl(path, [{"type": "user", "timestamp": f"2026-01-0{index + 1}", "message": {"content": "prompt"}}])
            os.utime(path, (100 + index, 100 + index))

        for index in range(3):
            path = self.codex / "sessions" / "2026" / "01" / "01" / f"rollout-codex-{index}.jsonl"
            self.write_jsonl(path, [
                {"type": "session_meta", "payload": {"id": f"codex-{index}"}},
                {"type": "event_msg", "timestamp": f"2026-01-0{index + 1}", "payload": {"type": "user_message", "message": "prompt"}},
            ])
            os.utime(path, (200 + index, 200 + index))

        db = self.data / "opencode" / "opencode.db"
        db.parent.mkdir(parents=True)
        connection = sqlite3.connect(db)
        connection.execute("CREATE TABLE session(id,directory,title,time_updated)")
        connection.executemany(
            "INSERT INTO session VALUES(?,?,?,?)",
            [(f"opencode-{i}", "/repo", f"title-{i}", i) for i in range(30)],
        )
        connection.commit()
        connection.close()

        rows = transcripts.list_transcripts(limit=12)
        counts = {source: sum(row["source"] == source for row in rows) for source in ("claude", "codex", "opencode")}
        self.assertEqual(len(rows), 12)
        self.assertEqual(counts, {"claude": 2, "codex": 3, "opencode": 7})
        opencode_ids = [row["session_id"] for row in rows if row["source"] == "opencode"]
        self.assertEqual(opencode_ids, [f"opencode-{i}" for i in range(29, 22, -1)])

    def test_mixed_timestamp_formats_sort_by_normalized_epoch(self):
        claude = self.claude / "projects" / "project" / "claude-time.jsonl"
        self.write_jsonl(claude, [{
            "type": "user", "timestamp": "2024-01-01T02:00:00+02:00", "message": {"content": "older"},
        }])
        codex = self.codex / "sessions" / "rollout-time.jsonl"
        self.write_jsonl(codex, [
            {"type": "session_meta", "payload": {"id": "codex-time"}},
            {"type": "event_msg", "timestamp": "1704153600", "payload": {"type": "user_message", "message": "middle"}},
        ])
        db = self.data / "opencode" / "opencode.db"
        db.parent.mkdir(parents=True)
        connection = sqlite3.connect(db)
        connection.execute("CREATE TABLE session(id,directory,title,time_updated)")
        connection.execute("INSERT INTO session VALUES(?,?,?,?)", ("opencode-time", "/repo", "newer", "1704240000000"))
        connection.commit()
        connection.close()

        rows = transcripts.list_transcripts(limit=3)
        self.assertEqual([row["source"] for row in rows], ["opencode", "codex", "claude"])
        self.assertEqual(transcripts._epoch_seconds("2024-01-01T00:00:00Z"), 1704067200.0)
        self.assertEqual(transcripts._epoch_seconds(1704067200), 1704067200.0)
        self.assertEqual(transcripts._epoch_seconds(1704067200000), 1704067200.0)
        self.assertEqual(transcripts._epoch_seconds("1704067200"), 1704067200.0)

    def test_index_cache_key_tracks_environment_overrides(self):
        first = self.claude / "projects" / "project" / "first.jsonl"
        self.write_jsonl(first, [{"type": "user", "message": {"content": "first"}}])
        self.assertEqual(transcripts.list_transcripts()[0]["session_id"], "first")

        alternate = self.root / "alternate-claude"
        self.write_jsonl(alternate / "projects" / "project" / "second.jsonl", [
            {"type": "user", "message": {"content": "second"}},
        ])
        with patch.dict(os.environ, {"CLAUDE_CONFIG_DIR": str(alternate)}):
            self.assertEqual(transcripts.list_transcripts()[0]["session_id"], "second")

    def test_large_messages_are_truncated_and_total_json_is_bounded(self):
        huge = "x" * 10_000
        claude_path = self.claude / "projects" / "project" / "claude-large.jsonl"
        self.write_jsonl(claude_path, [
            {"type": "user", "timestamp": "2026-01-01T00:00:00Z", "message": {"content": huge}}
            for _ in range(85)
        ])

        codex_path = self.codex / "sessions" / "rollout-large.jsonl"
        self.write_jsonl(codex_path, [
            {"type": "session_meta", "payload": {"id": "codex-large"}},
            *[{
                "type": "event_msg", "timestamp": str(index),
                "payload": {"type": "agent_message", "message": huge},
            } for index in range(85)],
        ])

        db = self.data / "opencode" / "opencode.db"
        db.parent.mkdir(parents=True)
        connection = sqlite3.connect(db)
        connection.executescript("CREATE TABLE session(id,directory,title,time_updated); CREATE TABLE message(id,session_id,data); CREATE TABLE part(message_id,session_id,data);")
        connection.execute("INSERT INTO session VALUES(?,?,?,?)", ("opencode-large", "/repo", "large", 10))
        for index in range(85):
            message_id = f"m-{index:03}"
            connection.execute("INSERT INTO message VALUES(?,?,?)", (message_id, "opencode-large", json.dumps({"role": "assistant", "time": {"created": index}})))
            connection.execute("INSERT INTO part VALUES(?,?,?)", (message_id, "opencode-large", json.dumps({"type": "text", "text": huge})))
        connection.commit()
        connection.close()

        for source, session_id in (("claude", "claude-large"), ("codex", "codex-large"), ("opencode", "opencode-large")):
            messages = transcripts.get_messages(source, session_id, limit=500)
            serialized = json.dumps(messages, ensure_ascii=False).encode("utf-8")
            self.assertLessEqual(len(messages), transcripts._MAX_MESSAGES)
            self.assertLessEqual(len(serialized), transcripts._MAX_MESSAGES_JSON_BYTES)
            self.assertTrue(messages)
            self.assertTrue(all(len(message["text"].encode("utf-8")) <= transcripts._MAX_MESSAGE_TEXT_BYTES for message in messages))
            self.assertTrue(any(message["text"].endswith("… [truncated]") for message in messages))


if __name__ == "__main__":
    unittest.main()
