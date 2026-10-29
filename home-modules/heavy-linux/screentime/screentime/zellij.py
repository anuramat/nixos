"""The zellij tracker: logs a class timeline for every pane that some client
of a local zellij session has focused."""

import json
import subprocess
import sys
import time

from . import core

COMMAND_LENGTH = 300  # chars of the pane's command given to the model


def run(cmd):
    """stdout, or None if the command fails or hangs."""
    try:
        return subprocess.run(
            cmd, check=True, capture_output=True, text=True, timeout=5
        ).stdout
    except (subprocess.SubprocessError, OSError) as e:
        print(f"{cmd} failed: {e!r}", file=sys.stderr)
        return None


def sessions(out):
    """Names of the running sessions, from `list-sessions -n`."""
    return [l.split(" ", 1)[0] for l in out.splitlines() if l and "(EXITED" not in l]


def focused(out):
    """pane_id -> running command for the panes focused by some client, from
    `list-clients`: `CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND`, after a header."""
    panes = {}
    for line in out.splitlines()[1:]:
        _, pane_id, *cmd = line.split(maxsplit=2)
        panes[pane_id] = cmd[0].strip() if cmd else ""
    return panes


def panes(out):
    """pane_id -> pane, from `list-panes -a --json`."""
    return {
        f"{'plugin' if p['is_plugin'] else 'terminal'}_{p['id']}": p
        for p in json.loads(out)
    }


def dir_class(cfg, cwd):
    """The dir map's class for the longest path containing cwd."""
    best = None
    for path, cls in cfg["dirs"].items():
        if (cwd == path or cwd.startswith(path.rstrip("/") + "/")) and (
            best is None or len(path) > len(best[0])
        ):
            best = path, cls
    return best and best[1]


def job(cfg, session, pane_id, command, cwd, run=run, post=None):
    text = run(["zellij", "-s", session, "action", "dump-screen", "-p", pane_id])
    if text is None:
        raise RuntimeError("dump-screen failed")
    state = {
        "command": command[:COMMAND_LENGTH],
        "working directory": cwd,
        "terminal screen": text,
    }
    return [core.ask("text", cfg, state, post=post)]


class Zellij:
    def __init__(self, cfg, db, now, submit=None, run=run, post=None):
        self.cfg, self.db, self.run, self.post = cfg, db, run, post
        self.spans = core.SpanLog(db, *core.PANE_SPANS)
        self.engine = core.Engine(
            cfg, db, self.spans, rate=6, burst=2, text_cost=1, now=now, submit=submit
        )

    def zellij(self, *args):
        return self.run(["zellij", *args])

    def tick(self, now):
        self.engine.poll(now)
        for session in sessions(self.zellij("list-sessions", "-n") or ""):
            clients = self.zellij("-s", session, "action", "list-clients")
            if clients is None:
                continue
            terminals = {
                p: cmd
                for p, cmd in focused(clients).items()
                if p.startswith("terminal_")
            }
            info = terminals and self.zellij(
                "-s", session, "action", "list-panes", "-a", "--json"
            )
            if not info:
                continue
            info = panes(info)
            for pane_id, client_cmd in terminals.items():
                self.pane(now, session, pane_id, info.get(pane_id, {}), client_cmd)
        # rows of panes that are no longer focused just stop being extended
        self.db.commit()

    def pane(self, now, session, pane_id, p, client_cmd):
        key = (session, pane_id)
        cwd = p.get("pane_cwd", "")
        cls = dir_class(self.cfg, cwd)
        target = None
        if cls:
            # leaving the dir is a fresh start
            self.engine.drop(lambda k: k == key)
        else:
            cls = self.engine.cls(key)
            if cls is None:
                cls, target = "pending", key
            if self.engine.due(key, now):
                command = p.get("pane_command") or client_cmd
                self.engine.start(
                    key,
                    lambda: job(
                        self.cfg, session, pane_id, command, cwd, self.run, self.post
                    ),
                )
        self.spans.record(now, key, (session, pane_id, cls), target)


def main(cfg):
    db = core.connect(core.state_path("screentime-zellij.db"))
    tracker = Zellij(cfg, db, time.time())
    while True:
        t = time.time()
        tracker.tick(t)
        time.sleep(max(0, core.TICK - (time.time() - t)))
