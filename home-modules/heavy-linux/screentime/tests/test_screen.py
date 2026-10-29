import json

import pytest
from conftest import fixture, json_fixture, rows

from screentime import screen

PANE = "ghostty - anuramat-bgm5/adamant-peach/terminal_3"


@pytest.mark.parametrize(
    "title, normalized",
    [
        ("(3) Inbox", "Inbox"),
        ("✳ claude", "claude"),
        ("⠋ (12) x (1)", "x (1)"),
        ("plain title", "plain title"),
        ("", ""),
    ],
)
def test_normalize(title, normalized):
    assert screen.normalize(title) == normalized


@pytest.mark.parametrize(
    "title, pane",
    [
        (PANE, "anuramat-bgm5/adamant-peach/terminal_3"),
        ("ghostty - h/s/terminal_12", "h/s/terminal_12"),
        ("ghostty - h/s/plugin_0", "h/s/plugin_0"),
    ],
)
def test_pane_title(cfg, title, pane):
    w = {"id": 1, "app_id": screen.GHOSTTY, "title": title}
    assert screen.resolve(cfg, w) == ("pane", pane)


@pytest.mark.parametrize(
    "title",
    [
        "ghostty",
        "ghostty - bash",
        "ghostty - h/s/terminal_x",
        "h/s/terminal_1",
        # e.g. a program outside zellij
        "ghostty - h/s/terminal_1 x",
        "ghostty - h/s/t/terminal_1",
        "ghostty - h/s s/terminal_1",
    ],
)
def test_ghostty_without_zellij(cfg, title):
    w = {"id": 1, "app_id": screen.GHOSTTY, "title": title}
    assert screen.resolve(cfg, w) == ("key", (1, screen.normalize(title)))


def test_resolve(cfg):
    assert screen.resolve(
        cfg, {"id": 1, "app_id": "org.telegram.desktop", "title": "x"}
    ) == (
        "class",
        "chat",
    )
    # firefox keys are shared between windows
    assert screen.resolve(cfg, {"id": 1, "app_id": "firefox", "title": "(2) Mail"}) == (
        "key",
        ("firefox", "Mail"),
    )
    assert screen.resolve(cfg, {"id": 7, "app_id": "mpv", "title": "a.mkv"}) == (
        "key",
        (7, "a.mkv"),
    )
    # the pane rule is ghostty's only
    assert screen.resolve(cfg, {"id": 7, "app_id": "mpv", "title": PANE})[0] == "key"


def test_screenshot():
    calls = []

    def run(cmd):
        calls.append(cmd)
        return (
            fixture("niri-focused-output.json").encode()
            if cmd[0] == "niri"
            else b"jpeg"
        )

    assert screen.screenshot(run) == b"jpeg"
    # 1920x1200 fit into 1024 px
    assert calls == [
        ["niri", "msg", "--json", "focused-output"],
        ["grim", "-o", "eDP-1", "-s", "0.5333", "-t", "jpeg", "-"],
    ]


def test_screenshot_small_output_not_upscaled():
    out = {"name": "X", "logical": {"width": 800, "height": 600}}
    calls = []

    def run(cmd):
        calls.append(cmd)
        return json.dumps(out).encode()

    screen.screenshot(run)
    assert calls[1][4] == "1.0000"


def window(id, app_id, title, focused=True):
    return {"id": id, "app_id": app_id, "title": title, "is_focused": focused}


def make(cfg, db, jobs, model):
    shots = []

    def shot():
        shots.append(1)
        return b"jpeg"

    s = screen.Screen(cfg, db, 0, submit=jobs.submit, screenshot=shot, post=model)
    return s, shots


def focus(s, w):
    s.on_event({"WindowOpenedOrChanged": {"window": w}})


def test_recorded_event_stream(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    for line in fixture("niri-event-stream.jsonl").splitlines():
        s.on_event(json.loads(line))
    assert s.focused == 31
    assert set(s.windows) == {31, 18}
    assert s.windows[18]["app_id"] == "firefox"


def test_windows_fixture_shape():
    (w,) = [w for w in json_fixture("niri-windows.json") if w["is_focused"]]
    assert {"id", "app_id", "title", "is_focused"} <= set(w)


def test_app_map_and_pane(cfg, db, jobs, model):
    s, shots = make(cfg, db, jobs, model)
    focus(s, window(1, "org.telegram.desktop", "Telegram"))
    s.tick(0)
    s.tick(2)
    focus(s, window(2, screen.GHOSTTY, PANE))
    s.tick(3)
    s.tick(4)
    assert rows(db, "spans") == [
        (0, 3, "chat", None),
        (3, 4, None, "anuramat-bgm5/adamant-peach/terminal_3"),
    ]
    assert jobs.queue == [] and shots == []


def test_firefox_confident_title(cfg, db, jobs, model):
    s, shots = make(cfg, db, jobs, model)
    focus(s, window(1, "firefox", "NixOS Wiki — Mozilla Firefox"))
    s.tick(0)
    model.answers.append(("nixos", 0.8))
    jobs.run()
    s.tick(2)
    s.tick(4)
    assert rows(db, "spans") == [(0, 4, "nixos", None)]
    (req,) = model.requests
    assert req["media"] == []
    assert req["state"] == {
        "focused window": {"app": "firefox", "title": "NixOS Wiki — Mozilla Firefox"}
    }
    # the recheck sends the screenshot too
    s.tick(32)
    model.answers.append(("nixos", 0.9))
    jobs.run()
    s.tick(34)
    assert len(model.requests[1]["media"]) == 1
    assert model.requests[1]["state"]["screenshot of the screen"] == "<image:1>"
    assert rows(db, "classifications") == [
        (2, rows(db, "classifications")[0][1], "title", "nixos", 0.8),
        (34, rows(db, "classifications")[0][1], "title+screenshot", "nixos", 0.9),
    ]


def test_firefox_unsure_title(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(1, "firefox", "Home"))
    s.tick(0)
    model.answers += [("web", 0.3), ("thesis", 0.9)]
    jobs.run()
    s.tick(2)
    assert [len(r["media"]) for r in model.requests] == [0, 1]
    assert rows(db, "spans") == [(0, 2, "thesis", None)]


def test_firefox_calibration_always_asks_both(cfg, db, jobs, model):
    cfg["calibration"] = True
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(1, "firefox", "Home"))
    s.tick(0)
    model.answers += [("web", 0.99), ("misc", 0.9)]
    jobs.run()
    s.tick(2)
    assert [r[2:4] for r in rows(db, "classifications")] == [
        ("title", "web"),
        ("title+screenshot", "misc"),
    ]
    assert rows(db, "classifications")[0][1] == "firefox/Home"


def test_firefox_title_cache_is_shared(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(1, "firefox", "Docs"))
    s.tick(0)
    model.answers.append(("coding", 0.9))
    jobs.run()
    s.tick(1)
    focus(s, window(2, "firefox", "(1) Docs"))
    s.tick(2)
    assert jobs.queue == []
    # closing a window keeps firefox entries
    s.on_event({"WindowClosed": {"id": 1}})
    assert ("firefox", "Docs") in s.engine.cache


def test_other_window_two_stages_and_pending(cfg, db, jobs, model):
    s, shots = make(cfg, db, jobs, model)
    focus(s, window(5, "mpv", "talk.mkv"))
    s.tick(0)
    s.tick(2)
    assert rows(db, "spans") == [(0, 2, "pending", None)]
    model.answers += [("web", 0.6), ("misc", 0.9)]
    jobs.run()
    s.tick(3)
    assert rows(db, "spans") == [(0, 3, "misc", None)]
    assert shots == [1]
    assert [r["state"] for r in model.requests] == [
        {"focused window": {"app": "mpv", "title": "talk.mkv"}},
        {
            "focused window": {"app": "mpv", "title": "talk.mkv"},
            "screenshot of the screen": "<image:1>",
        },
    ]
    assert [len(r["media"]) for r in model.requests] == [0, 1]
    # a title change is a new key; the old class holds nothing over
    focus(s, window(5, "mpv", "other.mkv"))
    s.tick(4)
    assert rows(db, "spans")[-1] == (4, 4, "pending", None)
    # closing the window drops its entries
    s.on_event({"WindowClosed": {"id": 5}})
    assert not any(k[0] == 5 for k in s.engine.cache)
    s.tick(5)
    assert rows(db, "spans")[-1] == (4, 5, "pending", None)


def test_other_window_confident_title(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(5, "org.pwmt.zathura", "~/books/photo/manual.pdf"))
    s.tick(0)
    model.answers.append(("misc", 0.9))
    jobs.run()
    s.tick(2)
    assert rows(db, "spans") == [(0, 2, "misc", None)]
    assert [len(r["media"]) for r in model.requests] == [0]
    # the recheck sends the screenshot
    s.tick(32)
    model.answers.append(("misc", 0.9))
    jobs.run()
    s.tick(33)
    assert [len(r["media"]) for r in model.requests] == [0, 1]


def test_calibration_asks_both_for_any_app(cfg, db, jobs, model):
    cfg["calibration"] = True
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(5, "mpv", "a"))
    s.tick(0)
    model.answers += [("misc", 0.99), ("misc", 0.9)]
    jobs.run()
    s.tick(2)
    assert [r[2] for r in rows(db, "classifications")] == ["title", "title+screenshot"]


def test_recheck_keeps_previous_class(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(5, "mpv", "a"))
    s.tick(0)
    model.answers.append(("misc", 0.9))
    jobs.run()
    for t in range(1, 34, 2):
        s.tick(t)  # the recheck starts at 31
    model.answers.append(("coding", 0.6))
    jobs.run()
    s.tick(34)
    assert rows(db, "spans") == [(0, 34, "misc", None), (34, 34, "coding", None)]


def test_pending_then_switch_away_and_back(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(5, "mpv", "a"))
    s.tick(0)
    focus(s, window(1, "org.telegram.desktop", "t"))
    s.tick(1)
    model.answers.append(("misc", 0.9))
    jobs.run()
    s.tick(2)
    # pending rows are filled in even when the window is no longer focused
    assert rows(db, "spans") == [(0, 1, "misc", None), (1, 2, "chat", None)]


def test_failure_is_unknown(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(5, "mpv", "a"))
    s.tick(0)
    model.answers.append(OSError("down"))
    jobs.run()
    s.tick(2)
    s.tick(4)
    assert rows(db, "spans") == [(0, 4, "unknown", None)]
    assert jobs.queue == []
    s.tick(32)  # retried at the recheck
    assert len(jobs.queue) == 1


def test_screenshot_failure_is_unknown(cfg, db, jobs, model):
    def shot():
        raise OSError("grim")

    s = screen.Screen(cfg, db, 0, submit=jobs.submit, screenshot=shot, post=model)
    focus(s, window(5, "mpv", "a"))
    s.tick(0)
    jobs.run()
    s.tick(2)
    assert rows(db, "spans") == [(0, 2, "unknown", None)]


def test_lock(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(1, "org.telegram.desktop", "t"))
    s.tick(0)
    s.locked = True
    s.tick(1)
    s.tick(3)
    focus(s, window(5, "mpv", "a"))
    s.tick(4)
    assert jobs.queue == []  # nothing is captured while locked
    s.locked = False
    s.tick(5)
    assert rows(db, "spans") == [
        (0, 1, "chat", None),
        (1, 5, "locked", None),
        (5, 5, "pending", None),
    ]
    assert len(jobs.queue) == 1


def test_no_focused_window(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    focus(s, window(1, "org.telegram.desktop", "t"))
    s.tick(0)
    s.on_event({"WindowFocusChanged": {"id": None}})
    s.tick(1)
    s.tick(3)
    s.on_event({"WindowFocusChanged": {"id": 1}})
    s.tick(4)
    assert rows(db, "spans") == [(0, 1, "chat", None), (4, 4, "chat", None)]


def test_windows_changed(cfg, db, jobs, model):
    s, _ = make(cfg, db, jobs, model)
    s.on_event(
        {
            "WindowsChanged": {
                "windows": [
                    window(1, "a", "x", focused=False),
                    window(2, "org.telegram.desktop", "t"),
                ]
            }
        }
    )
    assert s.focused == 2
    s.on_event({"WindowsChanged": {"windows": [window(1, "a", "x", focused=False)]}})
    assert s.focused is None
    # an unfocused change doesn't move focus
    s.on_event({"WindowFocusChanged": {"id": 1}})
    focus(s, window(3, "b", "y", focused=False))
    assert s.focused == 1
    # other events are ignored
    s.on_event({"KeyboardLayoutsChanged": {}})
