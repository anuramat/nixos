"""The real entry points, against fake niri, grim and zellij executables and
a local HTTP decision model."""

import json
import os
import signal
import socket
import sqlite3
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import pytest
from conftest import FIXTURES

from screentime import core


@pytest.fixture
def model_url():
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            requests.append(body)
            out = json.dumps(
                {"answers": {"class": {"choice": "web", "confidence": 0.9}}}
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(out.encode())

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_port}/v1/systemone", requests
    server.shutdown()


def fake(bin, name, code):
    p = bin / name
    p.write_text(f"#!{sys.executable}\nimport sys, time\nargs = sys.argv[1:]\n{code}\n")
    p.chmod(0o755)


@pytest.fixture
def env(tmp_path, cfg, model_url):
    bin = tmp_path / "bin"
    bin.mkdir()
    fake(
        bin,
        "niri",
        f"""
if args == ["msg", "--json", "event-stream"]:
    sys.stdout.write(open({str(FIXTURES / "niri-event-stream.jsonl")!r}).read())
    sys.stdout.flush()
    time.sleep(1)
    print('{{"WindowFocusChanged": {{"id": 18}}}}', flush=True)
    time.sleep(600)
elif args == ["msg", "--json", "focused-output"]:
    sys.stdout.write(open({str(FIXTURES / "niri-focused-output.json")!r}).read())
""",
    )
    fake(bin, "grim", "sys.stdout.buffer.write(b'jpeg')")
    fake(
        bin,
        "zellij",
        f"""
fixtures = {str(FIXTURES)!r}
if args == ["list-sessions", "-n"]:
    sys.stdout.write(open(fixtures + "/zellij-list-sessions.txt").read())
elif args[3] == "list-clients":
    sys.stdout.write(open(fixtures + "/zellij-list-clients.txt").read())
elif args[3] == "list-panes":
    sys.stdout.write(open(fixtures + "/zellij-list-panes.json").read())
elif args[3] == "dump-screen":
    print("$ lazygit")
""",
    )
    cfg["url"] = model_url[0]
    (tmp_path / "config" / "screentime").mkdir(parents=True)
    (tmp_path / "config" / "screentime" / "config.json").write_text(json.dumps(cfg))
    (tmp_path / "state").mkdir()
    return {
        **os.environ,
        "PATH": f"{bin}:{os.environ['PATH']}",
        "XDG_CONFIG_HOME": str(tmp_path / "config"),
        "XDG_STATE_HOME": str(tmp_path / "state"),
        "PYTHONPATH": str(Path(__file__).parent.parent)
        + ":"
        + os.environ.get("PYTHONPATH", ""),
    }


def screentime(env, *args, **kw):
    return subprocess.Popen(
        [sys.executable, "-c", "from screentime.cli import main; main()", *args],
        env=env,
        **kw,
    )


def wait_for(db_path, query, timeout=10):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if db_path.exists():
            try:
                rows = sqlite3.connect(db_path).execute(query).fetchall()
            except sqlite3.OperationalError:
                rows = []
            if rows:
                return rows
        time.sleep(0.1)
    raise TimeoutError(query)


def test_screen(env, model_url):
    db = Path(env["XDG_STATE_HOME"]) / "screentime.db"
    p = screentime(env, "screen")
    try:
        # the focused ghostty window, without zellij, then firefox
        wait_for(db, "select * from spans where class = 'web'")
        time.sleep(1.5)
        p.send_signal(signal.SIGUSR1)
        t = time.time()
        (locked,) = wait_for(
            db, "select start from spans where class = 'locked'", timeout=1
        )
        # the signal wakes the tracker up, without waiting for a tick
        assert locked[0] - t < 0.5
        p.send_signal(signal.SIGUSR2)
        wait_for(
            db,
            "select * from spans where class != 'locked' and start > (select start from spans where class = 'locked')",
        )
    finally:
        p.terminate()
        p.wait()
    states = [r["state"] for r in model_url[1]]
    assert states[0]["focused window"] == {
        "app": "com.mitchellh.ghostty",
        "title": "ghostty",
    }
    assert any(s["focused window"]["app"] == "firefox" for s in states)
    # the model is confident, so the titles are enough
    assert all(r["media"] == [] for r in model_url[1])


def test_screen_exits_when_niri_does(env, tmp_path):
    fake(tmp_path / "bin", "niri", "pass")
    p = screentime(env, "screen", stderr=subprocess.PIPE, text=True)
    assert p.wait(timeout=10) != 0
    assert "event stream ended" in p.stderr.read()


def test_zellij(env, model_url):
    db = Path(env["XDG_STATE_HOME"]) / "screentime-zellij.db"
    p = screentime(env, "zellij")
    try:
        rows = wait_for(
            db, "select session, pane_id, class from pane_spans where class = 'web'"
        )
    finally:
        p.terminate()
        p.wait()
    assert rows[0] == ("glowing-apple", "terminal_238", "web")
    assert model_url[1][0]["state"]["terminal screen"] == "$ lazygit\n"


def test_report_and_zellij_log(env):
    state = Path(env["XDG_STATE_HOME"])
    host = socket.gethostname()
    now = time.time()
    db = core.connect(state / "screentime.db")
    spans = core.SpanLog(db, "spans", ("class", "pane"))
    spans.record(now - 3600, (), (None, f"{host}/s/terminal_1"))
    spans.record(now - 3599, (), (None, f"{host}/s/terminal_1"))
    db.commit()
    zdb = core.connect(state / "screentime-zellij.db")
    panes = core.SpanLog(zdb, "pane_spans", ("session", "pane_id", "class"))
    panes.record(now - 3601, ("s", "terminal_1"), ("s", "terminal_1", "nixos"))
    panes.record(now - 3598, ("s", "terminal_1"), ("s", "terminal_1", "nixos"))
    zdb.commit()
    out = subprocess.run(
        [
            sys.executable,
            "-c",
            "from screentime.cli import main; main()",
            "zellij-log",
            "0",
        ],
        env=env,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    assert json.loads(out) == {
        "pane_spans": [[now - 3601, now - 3598, "s", "terminal_1", "nixos"]],
        "calls": [],
    }
    out = subprocess.run(
        [
            sys.executable,
            "-c",
            "from screentime.cli import main; main()",
            "report",
            "--since",
            "1 day ago",
        ],
        env=env,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    assert out.splitlines()[0].split() == ["day", "nixos", "total", "calls"]
