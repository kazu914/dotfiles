import http.client
import json
import sys
import threading
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch
from urllib.parse import quote

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import server


class ServerTests(unittest.TestCase):
    def setUp(self):
        self.httpd = server.LocalHTTPServer(("127.0.0.1", 0), server.DashboardHandler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()
        self.port = self.httpd.server_port

    def tearDown(self):
        self.httpd.shutdown()
        self.httpd.server_close()
        self.thread.join(timeout=2)

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=3)
        connection.request(method, path, body=body, headers={"Host": f"127.0.0.1:{self.port}", **(headers or {})})
        response = connection.getresponse()
        data = response.read()
        result = json.loads(data) if response.getheader("Content-Type", "").startswith("application/json") else data
        connection.close()
        return response.status, result, response

    def test_sessions_include_live_panes_and_separate_unmatched_history(self):
        snapshot = {
            "agents": [{"agent": "claude", "agent_status": "running", "cwd": "/repo", "pane_id": "p/1",
                        "tab_id": "t1", "workspace_id": "w1",
                        "agent_session": {"source": "herdr:claude", "agent": "claude", "kind": "id", "value": "sid"}}],
            "panes": [{"pane_id": "p/1", "workspace_id": "w1", "tab_id": "t1", "cwd": "/repo"},
                      {"pane_id": "p2", "workspace_id": "w1", "tab_id": "t1", "cwd": "/other"}],
            "workspaces": [{"workspace_id": "w1", "label": "Project"}], "tabs": [],
        }
        history = [{"source": "claude", "session_id": "sid", "title": "Bound", "cwd": "/wrong", "updated_at": "t1"},
                   {"source": "codex", "session_id": "old/id", "title": "Old", "cwd": "/old", "updated_at": "t2"}]
        with patch.object(server, "_snapshot", return_value=snapshot), patch.object(server, "list_transcripts", return_value=history):
            status, data, response = self.request("GET", "/api/sessions")
        self.assertEqual(status, 200)
        rows = data["sessions"]
        self.assertEqual([row["key"] for row in rows], ["pane:p/1", "history:codex:old/id"])
        self.assertEqual(rows[0]["status"], "working")
        self.assertEqual(rows[0]["title"], "Bound")
        self.assertEqual(rows[1]["status"], "not_active")
        self.assertEqual(rows[1]["status_source"], "Herdr に稼働ペインなし（終了は未確認）")
        self.assertFalse(rows[1]["active"])
        self.assertEqual(response.getheader("Cache-Control"), "no-store")
        self.assertEqual(response.getheader("X-Content-Type-Options"), "nosniff")

    def test_sessions_http_orders_live_statuses_across_workspaces_then_history(self):
        snapshot = {
            "agents": [
                {"agent": "claude", "agent_status": "working", "pane_id": "work", "workspace_id": "w-m"},
                {"agent": "codex", "agent_status": "idle", "pane_id": "idle", "workspace_id": "w-a"},
                {"agent": "opencode", "agent_status": "blocked", "pane_id": "blocked", "workspace_id": "w-z"},
                {"agent": "claude", "pane_id": "unknown", "workspace_id": "w-b"},
            ],
            "panes": [
                {"pane_id": "work", "workspace_id": "w-m"},
                {"pane_id": "idle", "workspace_id": "w-a"},
                {"pane_id": "blocked", "workspace_id": "w-z"},
                {"pane_id": "unknown", "workspace_id": "w-b"},
            ],
            "workspaces": [
                {"workspace_id": "w-a", "label": "Alpha"},
                {"workspace_id": "w-b", "label": "Beta"},
                {"workspace_id": "w-m", "label": "Middle"},
                {"workspace_id": "w-z", "label": "Zulu"},
            ],
        }
        history = [{"source": "codex", "session_id": "history", "title": "History", "cwd": "/history",
                    "updated_at": "9999999999999"}]
        with patch.object(server, "_snapshot", return_value=snapshot), \
                patch.object(server, "list_transcripts", return_value=history):
            status, data, _ = self.request("GET", "/api/sessions")
        self.assertEqual(status, 200)
        rows = data["sessions"]
        self.assertEqual([row["key"] for row in rows], [
            "pane:blocked", "pane:idle", "pane:work", "pane:unknown", "history:codex:history",
        ])
        self.assertEqual([row["status"] for row in rows], [
            "blocked", "idle", "working", "unknown", "not_active",
        ])

    def test_sessions_show_only_agent_panes_not_unlabeled_shell_panes(self):
        agents = [
            {"agent": "claude", "agent_status": "working", "pane_id": "p1"},
            {"agent": "opencode", "agent_status": "idle", "pane_id": "p2"},
        ]
        panes = [{"pane_id": f"p{i}"} for i in range(1, 17)]
        snapshot = {"agents": agents, "panes": panes}
        with patch.object(server, "_snapshot", return_value=snapshot), \
                patch.object(server, "list_transcripts", return_value=[]):
            status, data, _ = self.request("GET", "/api/sessions")
        self.assertEqual(status, 200)
        self.assertEqual([row["pane_id"] for row in data["sessions"]], ["p2", "p1"])
        self.assertEqual([row["agent"] for row in data["sessions"]], ["OpenCode", "Claude"])

    def test_message_falls_back_to_safe_terminal_preview_when_no_transcript_ref(self):
        snapshot = {
            "agents": [{"agent": "claude", "agent_status": "working", "pane_id": "agent-pane"}],
            "panes": [{"pane_id": "agent-pane"}, {"pane_id": "shell-pane"}],
        }
        with patch.object(server, "_snapshot", side_effect=[snapshot, snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "_ipc", return_value={"read": {"text": "\x1b[32mRecent output\x1b[0m\x01\n"}}) as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertTrue(data["preview"])
        self.assertEqual(data["messages"], [{"role": "terminal", "text": "Recent output", "timestamp": ""}])
        ipc.assert_called_once_with("pane.read", {
            "pane_id": "agent-pane", "source": "recent", "format": "text", "lines": 60,
        })

    def test_terminal_read_requires_pane_in_fresh_snapshot(self):
        listed_snapshot = {"agents": [{"agent": "claude", "pane_id": "agent-pane"}],
                           "panes": [{"pane_id": "agent-pane"}]}
        fresh_snapshot = {"agents": [], "panes": []}
        with patch.object(server, "_snapshot", side_effect=[listed_snapshot, fresh_snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "_ipc") as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertEqual(data["messages"], [])
        self.assertIn("再読み込み", data["error"])
        ipc.assert_not_called()

    def test_terminal_preview_is_blocked_when_session_reference_changes_after_listing(self):
        listed_snapshot = {
            "agents": [{"agent": "claude", "pane_id": "agent-pane", "agent_session": {
                "source": "herdr:claude", "kind": "id", "value": "listed-session"}}],
            "panes": [{"pane_id": "agent-pane"}],
        }
        fresh_snapshot = {
            "agents": [{"agent": "claude", "pane_id": "agent-pane", "agent_session": {
                "source": "herdr:claude", "kind": "id", "value": "different-session"}}],
            "panes": [{"pane_id": "agent-pane"}],
        }
        with patch.object(server, "_snapshot", side_effect=[listed_snapshot, fresh_snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "get_messages", return_value=[]), \
                patch.object(server, "_ipc") as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertEqual(data["messages"], [])
        self.assertIn("再読み込み", data["error"])
        ipc.assert_not_called()

    def test_idless_listing_is_not_previewed_after_native_id_appears(self):
        listed_snapshot = {"agents": [{"agent": "claude", "pane_id": "agent-pane"}],
                           "panes": [{"pane_id": "agent-pane"}]}
        fresh_snapshot = {
            "agents": [{"agent": "claude", "pane_id": "agent-pane", "agent_session": {
                "source": "herdr:claude", "kind": "id", "value": "new-session"}}],
            "panes": [{"pane_id": "agent-pane"}],
        }
        with patch.object(server, "_snapshot", side_effect=[listed_snapshot, fresh_snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "_ipc") as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertEqual(data["messages"], [])
        self.assertIn("再読み込み", data["error"])
        ipc.assert_not_called()

    def test_id_without_indexed_transcript_can_still_use_terminal_preview(self):
        snapshot = {
            "agents": [{"agent": "claude", "pane_id": "agent-pane", "agent_session": {
                "source": "herdr:claude", "kind": "id", "value": "unindexed-session"}}],
            "panes": [{"pane_id": "agent-pane"}],
        }
        with patch.object(server, "_snapshot", side_effect=[snapshot, snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "get_messages", return_value=[]), \
                patch.object(server, "_ipc", return_value={"read": {"text": "Terminal output"}}) as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertTrue(data["preview"])
        self.assertEqual(data["messages"], [{"role": "terminal", "text": "Terminal output", "timestamp": ""}])
        ipc.assert_called_once_with("pane.read", {
            "pane_id": "agent-pane", "source": "recent", "format": "text", "lines": 60,
        })

    def test_native_transcript_messages_are_preferred_over_terminal_preview(self):
        snapshot = {
            "agents": [{"agent": "claude", "pane_id": "agent-pane", "agent_session": {
                "source": "herdr:claude", "agent": "claude", "kind": "id", "value": "session-id"}}],
            "panes": [{"pane_id": "agent-pane"}],
        }
        messages = [{"role": "assistant", "text": "Native transcript", "timestamp": "t"}]
        with patch.object(server, "_snapshot", return_value=snapshot), \
                patch.object(server, "list_transcripts", return_value=[{
                    "source": "claude", "session_id": "session-id", "title": "Title", "cwd": "", "updated_at": "",
                }]), \
                patch.object(server, "get_messages", return_value=messages) as get_messages, \
                patch.object(server, "_ipc") as ipc:
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        self.assertEqual(status, 200)
        self.assertEqual(data["messages"], messages)
        self.assertNotIn("preview", data)
        get_messages.assert_called_once_with("claude", "session-id", limit=80)
        ipc.assert_not_called()

    def test_terminal_preview_read_failure_or_empty_output_explains_unavailable(self):
        snapshot = {"agents": [{"agent": "codex", "pane_id": "agent-pane"}],
                    "panes": [{"pane_id": "agent-pane"}]}
        for read_result in (OSError("read failed"), {"read": {"text": "\x1b[0m\x01  \n"}}):
            with self.subTest(read_result=read_result), \
                    patch.object(server, "_snapshot", side_effect=[snapshot, snapshot]), \
                    patch.object(server, "list_transcripts", return_value=[]), \
                    patch.object(server, "_ipc", side_effect=read_result):
                status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
            self.assertEqual(status, 200)
            self.assertEqual(data["messages"], [])
            self.assertIn("端末表示を取得できません", data["error"])
            self.assertNotIn("再起動", data["error"])

    def test_terminal_preview_is_sanitized_and_limited_to_16_kib(self):
        snapshot = {"agents": [{"agent": "opencode", "pane_id": "agent-pane"}],
                    "panes": [{"pane_id": "agent-pane"}]}
        terminal_text = "\x1b[31m" + ("x" * (server._MAX_TERMINAL_PREVIEW_BYTES + 1000)) + "\x1b[0m\x01"
        with patch.object(server, "_snapshot", side_effect=[snapshot, snapshot]), \
                patch.object(server, "list_transcripts", return_value=[]), \
                patch.object(server, "_ipc", return_value={"read": {"text": terminal_text}}):
            status, data, _ = self.request("GET", "/api/sessions/pane%3Aagent-pane/messages")
        text = data["messages"][0]["text"]
        self.assertEqual(status, 200)
        self.assertLessEqual(len(text.encode("utf-8")), server._MAX_TERMINAL_PREVIEW_BYTES)
        self.assertNotIn("\x1b", text)
        self.assertNotIn("\x01", text)

    def test_herdr_native_session_references_are_normalized_and_validated(self):
        snapshot = {
            "agents": [
                {"agent": "codex", "agent_status": "working", "pane_id": "good", "agent_session": {
                    "source": "herdr:codex", "agent": "codex", "kind": "id", "value": "native-id"}},
                {"agent": "claude", "pane_id": "wrong-agent", "agent_session": {
                    "source": "herdr:codex", "agent": "codex", "kind": "id", "value": "native-id"}},
                {"agent": "codex", "pane_id": "dummy", "agent_session": {
                    "source": "herdr:codex", "agent": "codex", "kind": "dummy", "value": "native-id"}},
            ],
            "panes": [{"pane_id": "good"}, {"pane_id": "wrong-agent"}, {"pane_id": "dummy"}],
        }
        history = [{"source": "codex", "session_id": "native-id", "title": "Native", "cwd": "/repo", "updated_at": "t"}]
        rows = server._records(snapshot, history)
        self.assertEqual(rows[0]["key"], "pane:good")
        self.assertEqual(rows[0]["source"], "codex")
        self.assertEqual(rows[0]["session_id"], "native-id")
        self.assertEqual(rows[0]["title"], "Native")
        self.assertEqual([row["key"] for row in rows[1:]], ["pane:dummy", "pane:wrong-agent"])
        self.assertTrue(all(row["session_id"] == "" for row in rows[1:3]))
        self.assertEqual(rows[-1]["status"], "unknown")

    def test_history_sort_normalizes_iso_and_millisecond_timestamps(self):
        transcripts = [
            {"source": "claude", "session_id": "iso", "updated_at": "2026-01-01T00:00:00Z"},
            {"source": "codex", "session_id": "millis", "updated_at": "1769904000000"},
            {"source": "opencode", "session_id": "seconds", "updated_at": "1769903900"},
        ]
        rows = server._records({}, transcripts)
        self.assertEqual([row["session_id"] for row in rows], ["millis", "seconds", "iso"])

    def test_no_native_reference_does_not_join_history_by_agent_or_cwd(self):
        snapshot = {
            "agents": [{"agent": "claude", "pane_id": "live", "cwd": "/same/project",
                        "terminal_title_stripped": "Live terminal"}],
            "panes": [{"pane_id": "live", "cwd": "/same/project"}],
        }
        history = [{"source": "claude", "session_id": "old-id", "title": "History", "cwd": "/same/project",
                    "updated_at": "1769904000000"}]
        rows = server._records(snapshot, history)
        self.assertEqual([row["key"] for row in rows], ["pane:live", "history:claude:old-id"])
        self.assertEqual(rows[0]["session_id"], "")
        self.assertEqual(rows[0]["title"], "Live terminal")
        self.assertEqual(rows[1]["status"], "not_active")
        self.assertEqual(rows[1]["status_source"], "Herdr に稼働ペインなし（終了は未確認）")
        self.assertFalse(rows[1]["active"])

    def test_successful_empty_snapshot_marks_history_not_active_not_ended(self):
        history = [{"source": "codex", "session_id": "old", "title": "Old", "cwd": "/repo", "updated_at": "t"}]
        rows = server._records({"panes": [], "agents": []}, history)
        self.assertEqual(rows[0]["status"], "not_active")
        self.assertEqual(rows[0]["status_source"], "Herdr に稼働ペインなし（終了は未確認）")
        self.assertFalse(rows[0]["active"])

    def test_live_title_falls_back_to_terminal_title_fields(self):
        rows = server._records({"agents": [
            {"agent": "claude", "pane_id": "stripped", "terminal_title_stripped": "Stripped"},
            {"agent": "codex", "pane_id": "fallback", "terminal_title": "Fallback"},
        ], "panes": [{"pane_id": "stripped"}, {"pane_id": "fallback"}]}, [])
        self.assertEqual({row["pane_id"]: row["title"] for row in rows},
                         {"stripped": "Stripped", "fallback": "Fallback"})

    def test_message_lookup_decodes_opaque_key_and_rejects_unknown_key(self):
        snapshot = {"agents": [], "panes": [], "workspaces": []}
        history = [{"source": "claude", "session_id": "id/with space", "title": "T", "cwd": "", "updated_at": ""}]
        with patch.object(server, "_snapshot", return_value=snapshot), patch.object(server, "list_transcripts", return_value=history), \
                patch.object(server, "get_messages", return_value=[{"role": "user", "text": "Hi", "timestamp": "now"}]) as messages:
            status, data, _ = self.request("GET", "/api/sessions/" + quote("history:claude:id/with space", safe="") + "/messages")
            self.assertEqual((status, data["messages"][0]["text"]), (200, "Hi"))
            messages.assert_called_once_with("claude", "id/with space", limit=80)
            status, data, _ = self.request("GET", "/api/sessions/history%3Aclaude%3A..%2Fsecret/messages")
        self.assertEqual(status, 404)
        self.assertIn("error", data)

    def test_static_allowlist_and_host_validation(self):
        status, body, response = self.request("GET", "/")
        self.assertEqual(status, 200)
        self.assertIn(b"<!doctype html>", body)
        self.assertEqual(response.getheader("Content-Type"), "text/html; charset=utf-8")
        self.assertEqual(self.request("GET", "/../server.py")[0], 404)
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=3)
        connection.request("GET", "/api/sessions", headers={"Host": "evil.test"})
        response = connection.getresponse()
        self.assertEqual(response.status, 400)
        connection.close()

    def test_snapshot_failure_returns_readable_history_with_nonfatal_warning(self):
        history = [{"source": "codex", "session_id": "old", "title": "Old", "cwd": "/repo", "updated_at": "t"}]
        with patch.object(server, "_snapshot", side_effect=OSError("offline")), patch.object(server, "list_transcripts", return_value=history), \
                patch.object(server, "get_messages", return_value=[{"role": "user", "text": "Readable", "timestamp": "t"}]):
            status, data, _ = self.request("GET", "/api/sessions")
            message_status, message_data, _ = self.request("GET", "/api/sessions/history%3Acodex%3Aold/messages")
        self.assertEqual(status, 200)
        self.assertEqual(data["sessions"][0]["key"], "history:codex:old")
        self.assertEqual(data["sessions"][0]["status"], "unknown")
        self.assertEqual(data["sessions"][0]["status_source"], "状態不明（Herdr snapshot 取得失敗）")
        self.assertNotIn("error", data)
        self.assertIn("warning", data)
        self.assertEqual(message_status, 200)
        self.assertEqual(message_data["messages"][0]["text"], "Readable")

    def test_oversized_json_response_fails_clearly_within_size_cap(self):
        history = [{"source": "claude", "session_id": "large", "title": "Large", "cwd": "", "updated_at": ""}]
        with patch.object(server, "_snapshot", return_value={"panes": [], "agents": []}), \
                patch.object(server, "list_transcripts", return_value=history), \
                patch.object(server, "get_messages", return_value=[{"role": "assistant", "text": "x" * (600 * 1024), "timestamp": ""}]):
            status, data, response = self.request("GET", "/api/sessions/history%3Aclaude%3Alarge/messages")
        self.assertEqual(status, 500)
        self.assertIn("上限", data["error"])
        self.assertLessEqual(int(response.getheader("Content-Length")), server._MAX_JSON_RESPONSE_BYTES)

    def test_focus_requires_security_headers_and_fresh_pane_validation(self):
        snapshot = {"panes": [{"pane_id": "safe"}], "agents": []}
        body = json.dumps({"pane_id": "safe"})
        with patch.object(server, "_snapshot", return_value=snapshot), patch.object(server, "_ipc", return_value={}) as ipc, \
                patch.object(server.subprocess, "run") as run, patch.dict("os.environ", {"HERDR_DASHBOARD_TERMINAL_APP": "Ghostty"}):
            headers = {"Origin": f"http://127.0.0.1:{self.port}", "X-Session-Dashboard": "1", "Content-Type": "application/json"}
            status, data, _ = self.request("POST", "/api/focus", body, headers)
            self.assertEqual((status, data), (200, {"ok": True}))
            ipc.assert_called_once_with("pane.focus", {"pane_id": "safe"})
            run.assert_called_once_with(["open", "-a", "Ghostty"], check=True,
                                        timeout=5, capture_output=True, text=True)
            ipc.reset_mock()
            status, data, _ = self.request("POST", "/api/focus", json.dumps({"pane_id": "arbitrary"}), headers)
            self.assertEqual(status, 404)
            self.assertFalse(data["ok"])
            ipc.assert_not_called()
            snapshot["panes"] = []
            snapshot["agents"] = [{"pane_id": "agent-only"}]
            status, data, _ = self.request("POST", "/api/focus", json.dumps({"pane_id": "agent-only"}), headers)
            self.assertEqual(status, 404)
            self.assertFalse(data["ok"])
            ipc.assert_not_called()

    def test_terminal_activation_failure_reports_pane_focused(self):
        headers = {"Origin": f"http://127.0.0.1:{self.port}", "X-Session-Dashboard": "1", "Content-Type": "application/json"}
        with patch.object(server, "_snapshot", return_value={"panes": [{"pane_id": "safe"}]}), \
                patch.object(server, "_ipc", return_value={}) as ipc, \
                patch.object(server.subprocess, "run", side_effect=OSError("open failed")) as run, \
                patch.dict("os.environ", {}, clear=True):
            status, data, _ = self.request("POST", "/api/focus", json.dumps({"pane_id": "safe"}), headers)
        self.assertEqual(status, 502)
        self.assertFalse(data["ok"])
        self.assertTrue(data["pane_focused"])
        ipc.assert_called_once_with("pane.focus", {"pane_id": "safe"})
        run.assert_called_once_with(["open", "-a", "Ghostty"], check=True,
                                    timeout=5, capture_output=True, text=True)

    def test_focus_rejects_missing_origin_or_custom_header(self):
        with patch.object(server, "_snapshot") as snapshot:
            status, data, _ = self.request("POST", "/api/focus", json.dumps({"pane_id": "p"}), {"Content-Type": "application/json"})
        self.assertEqual(status, 403)
        self.assertFalse(data["ok"])
        snapshot.assert_not_called()

    def test_ipc_uses_newline_json_and_checks_response_id(self):
        fake_socket = MagicMock()
        fake_socket.__enter__.return_value = fake_socket
        fake_socket.recv.side_effect = [b'{"id":"request-id","result":{"snapshot":{}}}\n']
        with patch.object(server.socket, "socket", return_value=fake_socket), patch.object(server.uuid, "uuid4", return_value="request-id"):
            result = server._ipc("session.snapshot", {})
        self.assertEqual(result, {"snapshot": {}})
        fake_socket.settimeout.assert_called_once_with(2.0)
        sent = json.loads(fake_socket.sendall.call_args.args[0])
        self.assertEqual(sent, {"id": "request-id", "method": "session.snapshot", "params": {}})
        bad_socket = MagicMock()
        bad_socket.__enter__.return_value = bad_socket
        bad_socket.recv.side_effect = [b'{"id":"wrong","result":{}}\n']
        with patch.object(server.socket, "socket", return_value=bad_socket), patch.object(server.uuid, "uuid4", return_value="request-id"):
            with self.assertRaisesRegex(RuntimeError, "ID が一致しません"):
                server._ipc("session.snapshot", {})


if __name__ == "__main__":
    unittest.main()
