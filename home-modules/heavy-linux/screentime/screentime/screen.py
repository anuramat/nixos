"""The screen tracker: follows niri focus, records a class, or the zellij pane
on screen, per moment."""

import json
import os
import re
import selectors
import signal
import subprocess
import sys
import time

from . import core

GHOSTTY = "com.mitchellh.ghostty"
FIREFOX = "firefox"
# written by the patched zellij and ghostty: ghostty - <host>/<session>/<pane_id>
PANE_TITLE = re.compile(r"ghostty - ([^/ ]+)/([^/ ]+)/((?:terminal|plugin)_\d+)")
SCREENSHOT_SIZE = 1024  # px the screenshot is fit into


def normalize(title):
    """Strips leading spinners, icons and a "(N)" counter."""
    return re.sub(r"^(?:\(\d+\)|\W)+", "", title)


def resolve(cfg, w):
    """The focused window's target: ("class", class), ("pane", pane) or
    ("key", cache key)."""
    if w["app_id"] in cfg["apps"]:
        return "class", cfg["apps"][w["app_id"]]
    if w["app_id"] == GHOSTTY and (m := PANE_TITLE.fullmatch(w["title"])):
        return "pane", "/".join(m.groups())
    if w["app_id"] == FIREFOX:
        # the same title always gets the same answer, in any window
        return "key", (FIREFOX, normalize(w["title"]))
    return "key", (w["id"], normalize(w["title"]))


def run(cmd):
    return subprocess.run(cmd, check=True, capture_output=True, timeout=10).stdout


def screenshot(run=run):
    """The focused output as JPEG bytes, fit into SCREENSHOT_SIZE. Tiled windows
    have no position in niri's IPC, so it's the whole output, not the window."""
    output = json.loads(run(["niri", "msg", "--json", "focused-output"]))
    logical = output["logical"]
    scale = min(1, SCREENSHOT_SIZE / max(logical["width"], logical["height"]))
    return run(["grim", "-o", output["name"], "-s", f"{scale:.4f}", "-t", "jpeg", "-"])


def job(cfg, w, first, screenshot=screenshot, post=None):
    """The answers for window w; first: whether it's the target's first
    classification, which starts with the title alone. The screenshot is taken
    first anyway, so that it shows what the title names."""
    state = {"focused window": {"app": w["app_id"], "title": w["title"]}}
    image = screenshot()
    answers = []
    if first:
        answers.append(core.ask("title", cfg, state, post=post))
        if not cfg["calibration"] and answers[0].confidence >= cfg["threshold"]:
            return answers
    state = state | {"screenshot of the screen": "<image:1>"}
    answers.append(core.ask("title+screenshot", cfg, state, image, post))
    return answers


class Screen:
    def __init__(self, cfg, db, now, submit=None, screenshot=screenshot, post=None):
        self.cfg, self.db = cfg, db
        self.spans = core.SpanLog(db, *core.SPANS)
        self.engine = core.Engine(
            cfg, db, self.spans, rate=4, burst=2, text_cost=0.25, now=now, submit=submit
        )
        self.screenshot, self.post = screenshot, post
        self.windows = {}  # id -> niri window
        self.focused = None  # window id
        self.locked = False

    def on_event(self, event):
        ((kind, body),) = event.items()
        if kind == "WindowsChanged":
            self.windows = {w["id"]: w for w in body["windows"]}
            self.focused = next(
                (w["id"] for w in body["windows"] if w["is_focused"]), None
            )
        elif kind == "WindowOpenedOrChanged":
            w = body["window"]
            self.windows[w["id"]] = w
            if w["is_focused"]:
                self.focused = w["id"]
        elif kind == "WindowClosed":
            self.windows.pop(body["id"], None)
            self.engine.drop(lambda key: key[0] == body["id"])
        elif kind == "WindowFocusChanged":
            self.focused = body["id"]

    def tick(self, now):
        self.engine.poll(now)
        w = self.windows.get(self.focused)
        value = target = None
        if self.locked:
            value = ("locked", None)
        elif w is not None:
            kind, x = resolve(self.cfg, w)
            if kind == "class":
                value = (x, None)
            elif kind == "pane":
                value = (None, x)
            else:
                cls = self.engine.cls(x)
                value = (cls or "pending", None)
                target = None if cls else x
                if self.engine.due(x, now):
                    first = cls is None
                    self.engine.start(
                        x, lambda: job(self.cfg, w, first, self.screenshot, self.post)
                    )
        self.spans.record(now, (), value, target)
        self.db.commit()


def main(cfg):
    db = core.connect(core.state_path("screentime.db"))
    screen = Screen(cfg, db, time.time())
    events = subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"], stdout=subprocess.PIPE
    )
    # the lock hooks signal the lock and the unlock; the wakeup fd makes the
    # select return right away
    wakeup_r, wakeup_w = os.pipe()
    os.set_blocking(wakeup_w, False)
    signal.set_wakeup_fd(wakeup_w)
    signal.signal(signal.SIGUSR1, lambda *_: setattr(screen, "locked", True))
    signal.signal(signal.SIGUSR2, lambda *_: setattr(screen, "locked", False))
    sel = selectors.DefaultSelector()
    sel.register(events.stdout, selectors.EVENT_READ)
    sel.register(wakeup_r, selectors.EVENT_READ)
    buf = b""
    while True:
        for key, _ in sel.select(core.TICK):
            if key.fileobj is events.stdout:
                data = os.read(events.stdout.fileno(), 1 << 16)
                if not data:
                    sys.exit("niri event stream ended")
                *lines, buf = (buf + data).split(b"\n")
                for line in lines:
                    screen.on_event(json.loads(line))
            else:
                os.read(wakeup_r, 512)
        screen.tick(time.time())
