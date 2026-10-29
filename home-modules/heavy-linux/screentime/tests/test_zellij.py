import json
import subprocess

import pytest
from conftest import fixture, rows

from screentime import zellij

VICODE = "/home/anuramat/.local/share/ghq/github.com/anuramat/vicode"


def test_sessions():
    assert zellij.sessions(fixture("zellij-list-sessions.txt")) == ["glowing-apple"]
    assert zellij.sessions("") == []
    assert zellij.sessions("a [Created 1s ago] \nb [Created 2s ago] (current)\n") == [
        "a",
        "b",
    ]


def test_focused():
    assert zellij.focused(fixture("zellij-list-clients.txt")) == {
        "terminal_238": "lazygit"
    }
    out = (
        "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n"
        "1         terminal_2     N/A            \n"
        "2         plugin_1       zellij:link    \n"
        "3         terminal_2     vim a b        \n"
    )
    assert zellij.focused(out) == {"terminal_2": "vim a b", "plugin_1": "zellij:link"}
    assert zellij.focused("CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n") == {}


def test_panes():
    p = zellij.panes(fixture("zellij-list-panes.json"))
    assert p["terminal_238"]["pane_cwd"] == VICODE
    assert p["terminal_233"]["pane_cwd"] == "/etc/nixos"
    # plugin and terminal ids overlap
    assert p["plugin_0"]["is_plugin"] and not p["terminal_71"]["is_plugin"]


@pytest.mark.parametrize(
    "cwd, cls",
    [
        ("/etc/nixos", "nixos"),
        ("/etc/nixos/overlays", "nixos"),
        ("/etc/nixosx", None),
        ("/home/u/thesis/src", "thesis"),
        # the longest prefix wins
        ("/home/u/thesis/vendor/nix/x", "nixos"),
        ("/home/u", None),
        ("", None),
    ],
)
def test_dir_class(cfg, cwd, cls):
    assert zellij.dir_class(cfg, cwd) == cls


class Zj:
    """A fake zellij CLI: one session, the recorded clients and panes."""

    def __init__(self):
        self.sessions = fixture("zellij-list-sessions.txt")
        self.clients = fixture("zellij-list-clients.txt")
        self.panes = json.loads(fixture("zellij-list-panes.json"))
        self.screen = "$ cargo test\nok"
        self.calls = []

    def __call__(self, cmd):
        self.calls.append(cmd)
        assert cmd[0] == "zellij"
        if cmd[1:] == ["list-sessions", "-n"]:
            return self.sessions
        _, _, session, _, action, *rest = cmd
        if action == "list-clients":
            return self.clients
        if action == "list-panes":
            return json.dumps(self.panes)
        if action == "dump-screen":
            return self.screen
        raise AssertionError(cmd)


def make(cfg, db, jobs, model, zj=None):
    zj = zj or Zj()
    return zellij.Zellij(cfg, db, 0, submit=jobs.submit, run=zj, post=model), zj


def test_tick_classifies_focused_pane(cfg, db, jobs, model):
    z, zj = make(cfg, db, jobs, model)
    z.tick(0)
    z.tick(2)
    assert rows(db, "pane_spans") == [
        (0, 2, "glowing-apple", "terminal_238", "pending")
    ]
    model.answers.append(("coding", 0.8))
    jobs.run()
    z.tick(4)
    assert rows(db, "pane_spans") == [(0, 4, "glowing-apple", "terminal_238", "coding")]
    (req,) = model.requests
    assert req["media"] == []
    assert req["state"] == {
        "command": "lazygit",
        "working directory": VICODE,
        "terminal screen": "$ cargo test\nok",
    }
    assert [
        "zellij",
        "-s",
        "glowing-apple",
        "action",
        "dump-screen",
        "-p",
        "terminal_238",
    ] in zj.calls
    assert rows(db, "classifications") == [
        (4, rows(db, "classifications")[0][1], "text", "coding", 0.8)
    ]


def test_pane_command_preferred(cfg, db, jobs, model):
    zj = Zj()
    for p in zj.panes:
        if p["id"] == 238 and not p["is_plugin"]:
            p["pane_command"] = "x" * 1000
    z, _ = make(cfg, db, jobs, model, zj)
    z.tick(0)
    model.answers.append(("coding", 0.8))
    jobs.run()
    z.tick(2)
    assert model.requests[0]["state"]["command"] == "x" * zellij.COMMAND_LENGTH


def test_dir_map_skips_the_model(cfg, db, jobs, model):
    cfg["dirs"][VICODE] = "thesis"
    z, zj = make(cfg, db, jobs, model)
    z.tick(0)
    z.tick(2)
    assert rows(db, "pane_spans") == [(0, 2, "glowing-apple", "terminal_238", "thesis")]
    assert jobs.queue == []


def test_leaving_a_mapped_dir(cfg, db, jobs, model):
    z, zj = make(cfg, db, jobs, model)
    z.tick(0)
    model.answers.append(("coding", 0.8))
    jobs.run()
    z.tick(2)
    for p in zj.panes:
        if p["id"] == 238 and not p["is_plugin"]:
            p["pane_cwd"] = "/etc/nixos"
    z.tick(4)
    assert ("glowing-apple", "terminal_238") not in z.engine.cache
    for p in zj.panes:
        if p["id"] == 238 and not p["is_plugin"]:
            p["pane_cwd"] = "/tmp"
    z.tick(6)
    assert rows(db, "pane_spans") == [
        (0, 4, "glowing-apple", "terminal_238", "coding"),
        (4, 6, "glowing-apple", "terminal_238", "nixos"),
        (6, 6, "glowing-apple", "terminal_238", "pending"),
    ]
    assert len(jobs.queue) == 1


def test_two_clients_two_panes(cfg, db, jobs, model):
    zj = Zj()
    zj.clients = (
        "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n"
        "1         terminal_238   lazygit        \n"
        "2         terminal_233   N/A            \n"
        "3         plugin_0       N/A            \n"
    )
    z, _ = make(cfg, db, jobs, model, zj)
    z.tick(0)
    z.tick(2)
    # one at a time; /etc/nixos is in the dir map
    assert sorted(rows(db, "pane_spans")) == [
        (0, 2, "glowing-apple", "terminal_233", "nixos"),
        (0, 2, "glowing-apple", "terminal_238", "pending"),
    ]
    assert len(jobs.queue) == 1


def test_unfocused_pane_stops(cfg, db, jobs, model):
    zj = Zj()
    cfg["dirs"][VICODE] = "thesis"
    z, _ = make(cfg, db, jobs, model, zj)
    z.tick(0)
    z.tick(2)
    zj.clients = (
        "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n1         terminal_233   N/A\n"
    )
    z.tick(4)
    z.tick(6)
    assert sorted(rows(db, "pane_spans")) == [
        (0, 2, "glowing-apple", "terminal_238", "thesis"),
        (4, 6, "glowing-apple", "terminal_233", "nixos"),
    ]


def test_plugin_panes_are_ignored(cfg, db, jobs, model):
    zj = Zj()
    zj.clients = (
        "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n1         plugin_0       N/A\n"
    )
    z, _ = make(cfg, db, jobs, model, zj)
    z.tick(0)
    assert rows(db, "pane_spans") == []
    # list-panes isn't even needed
    assert not any("list-panes" in c for c in zj.calls)


def test_cli_failures(cfg, db, jobs, model):
    zj = Zj()
    z, _ = make(cfg, db, jobs, model, zj)
    zj.sessions = None
    z.tick(0)
    zj.sessions = fixture("zellij-list-sessions.txt")
    zj.clients = None
    z.tick(2)
    assert rows(db, "pane_spans") == []


def test_dump_screen_failure_is_unknown(cfg, db, jobs, model):
    zj = Zj()
    zj.screen = None
    z, _ = make(cfg, db, jobs, model, zj)
    z.tick(0)
    jobs.run()
    z.tick(2)
    assert rows(db, "pane_spans") == [
        (0, 2, "glowing-apple", "terminal_238", "unknown")
    ]
    assert model.requests == []


def test_rate_limit(cfg, db, jobs, model):
    zj = Zj()
    zj.clients = (
        "CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND\n"
        "1         terminal_238   lazygit        \n"
        "2         terminal_71    N/A            \n"
        "3         terminal_77    N/A            \n"
    )
    z, _ = make(cfg, db, jobs, model, zj)
    for t in range(0, 10, 2):
        z.tick(t)
        model.answers.append(("coding", 0.8))
        jobs.run()
    # burst 2, then a token per 10 s
    assert len(model.requests) == 2


def test_run(tmp_path):
    assert zellij.run(["echo", "hi"]) == "hi\n"
    assert zellij.run(["false"]) is None
    assert zellij.run([str(tmp_path / "missing")]) is None


def test_run_timeout(monkeypatch):
    def hang(*a, **kw):
        raise subprocess.TimeoutExpired("zellij", 5)

    monkeypatch.setattr(subprocess, "run", hang)
    assert zellij.run(["zellij"]) is None
