import json
import sqlite3
from datetime import date, datetime

import pytest

from screentime import core, report


def ts(day, hour, minute=0):
    return datetime(2026, 10, day, hour, minute).timestamp()


D28, D29 = date(2026, 10, 28), date(2026, 10, 29)


def test_split_days():
    assert list(report.split_days(ts(28, 23), ts(29, 1))) == [(D28, 3600), (D29, 3600)]
    assert list(report.split_days(ts(28, 1), ts(28, 1))) == []
    assert list(report.split_days(ts(28, 1), ts(28, 2))) == [(D28, 3600)]


def test_gaps():
    assert list(report.gaps(0, 10, [])) == [(0, 10)]
    assert list(report.gaps(0, 10, [(2, 3), (5, 10)])) == [(0, 2), (3, 5)]
    assert list(report.gaps(0, 10, [(5, 6), (0, 2)])) == [(2, 5), (6, 10)]
    assert list(report.gaps(0, 10, [(0, 10)])) == []
    assert list(report.gaps(0, 10, [(0, 4), (4, 12)])) == []


def test_totals_classes():
    spans = [
        (ts(29, 9), ts(29, 10), "web", None),
        (ts(29, 10), ts(29, 10, 30), "web", None),
        (ts(29, 11), ts(29, 11, 10), "pending", None),
        (ts(29, 12), ts(29, 12, 5), "locked", None),
    ]
    out = report.totals(spans, {}, since=0)
    assert out == {(D29, "web"): 5400, (D29, "unknown"): 600, (D29, "locked"): 300}


def test_totals_since_clips():
    spans = [(ts(28, 23), ts(29, 1), "web", None)]
    assert report.totals(spans, {}, since=ts(29, 0, 30)) == {(D29, "web"): 1800}


def test_totals_panes():
    pane = "bgm5/s/terminal_1"
    spans = [(ts(29, 9), ts(29, 10), None, pane)]
    pane_rows = {
        "bgm5": [
            # before the screen span
            [ts(29, 8), ts(29, 9, 15), "s", "terminal_1", "nixos"],
            [ts(29, 9, 15), ts(29, 9, 30), "s", "terminal_1", "pending"],
            # a gap from 9:30 to 9:40
            [ts(29, 9, 40), ts(29, 11), "s", "terminal_1", "coding"],
            # other panes and sessions
            [ts(29, 9), ts(29, 10), "s", "terminal_2", "web"],
            [ts(29, 9), ts(29, 10), "t", "terminal_1", "web"],
        ]
    }
    out = report.totals(spans, pane_rows, since=0)
    assert out == {
        (D29, "nixos"): 900,
        (D29, "unknown"): 900 + 600,
        (D29, "coding"): 1200,
    }


def test_totals_unreachable_host():
    spans = [(ts(29, 9), ts(29, 10), None, "root/s/terminal_1")]
    assert report.totals(spans, {"root": None}, since=0) == {(D29, "unknown"): 3600}
    # a host without a zellij tracker
    assert report.totals(spans, {}, since=0) == {(D29, "unknown"): 3600}


def test_table(cfg):
    out = {
        (D28, "web"): 3600,
        (D29, "nixos"): 5440,
        (D29, "web"): 60,
        (D29, "unknown"): 29,
    }
    assert report.table(cfg, out, {D29: 1234}).splitlines() == [
        "day           nixos      web  unknown    total  calls",
        "2026-10-28  0:00:00  1:00:00  0:00:00  1:00:00      0",
        "2026-10-29  1:30:40  0:01:00  0:00:29  1:32:09   1234",
    ]


def test_table_calls_without_time(cfg):
    # e.g. a zellij tracker's calls on a day the screen tracker didn't run
    assert report.table(cfg, {}, {D28: 3}).splitlines() == [
        "day           total  calls",
        "2026-10-28  0:00:00      3",
    ]


def test_table_empty(cfg):
    assert report.table(cfg, {}, {}) == "day  total  calls"


def test_calls_per_day():
    assert report.calls_per_day([ts(28, 23), ts(29, 0, 1), ts(29, 12)]) == {
        D28: 1,
        D29: 2,
    }


def log_call(db, t):
    core.classification_log(db)
    db.execute("insert into classifications values (?, 'k', 'text', 'web', 0.5)", (t,))


def test_zellij_log(db):
    s = core.SpanLog(db, "pane_spans", ("session", "pane_id", "class"))
    s.record(1, ("a", "terminal_1"), ("a", "terminal_1", "web"))
    s.record(3, ("a", "terminal_1"), ("a", "terminal_1", "web"))
    s.record(10, ("a", "terminal_1"), ("a", "terminal_1", "chat"))
    for t in (1, 5, 9):
        log_call(db, t)
    assert report.zellij_log(db, 2) == {
        "pane_spans": [
            [1, 3, "a", "terminal_1", "web"],
            [10, 10, "a", "terminal_1", "chat"],
        ],
        "calls": [5, 9],
    }
    assert report.zellij_log(db, 3)["pane_spans"] == [
        [10, 10, "a", "terminal_1", "chat"]
    ]
    json.dumps(report.zellij_log(db, 0))


def test_main(cfg, monkeypatch, tmp_path, capsys):
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    db = core.connect(tmp_path / "screentime.db")
    s = core.SpanLog(db, "spans", ("class", "pane"))
    t = ts(29, 9)
    for dt, value in [
        (0, ("web", None)),
        (2, ("web", None)),
        (3, (None, "bgm5/s/terminal_1")),
        (5, (None, "bgm5/s/terminal_1")),
        (6, (None, "root/s/terminal_1")),
        (8, (None, "root/s/terminal_1")),
    ]:
        s.record(t + dt, (), value)
    # the screen tracker's calls; one before since
    for t in (ts(28, 12), ts(29, 9), ts(29, 9, 1)):
        log_call(db, t)
    db.commit()
    monkeypatch.setattr(report.socket, "gethostname", lambda: "here")
    fetched = []

    def fetch(host, since):
        fetched.append((host, since))
        if host == "root":
            raise OSError("unreachable")
        if host == "here":
            return {"pane_spans": [], "calls": [ts(29, 11)]}
        return {
            "pane_spans": [[ts(29, 9), ts(29, 10), "s", "terminal_1", "nixos"]],
            "calls": [ts(29, 9), ts(29, 10)],
        }

    report.main(cfg, ts(29, 0), fetch)
    out, err = capsys.readouterr()
    # this host's zellij tracker is read even without its panes on screen
    assert fetched == [("bgm5", ts(29, 0)), ("here", ts(29, 0)), ("root", ts(29, 0))]
    assert "root" in err and "unknown" in err
    header, row = out.splitlines()
    assert header.split() == ["day", "nixos", "web", "unknown", "total", "calls"]
    assert row.split() == [
        "2026-10-29",
        "0:00:03",
        "0:00:03",
        "0:00:02",
        "0:00:08",
        "5",
    ]


def test_empty_databases(cfg, monkeypatch, tmp_path, capsys):
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    report.main(cfg, 0)
    assert capsys.readouterr().out == "day  total  calls\n"
    assert report.zellij_log(sqlite3.connect(":memory:"), 0) == {
        "pane_spans": [],
        "calls": [],
    }


def test_fetch_local(monkeypatch, tmp_path):
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path))
    monkeypatch.setattr(report.socket, "gethostname", lambda: "here")
    db = sqlite3.connect(tmp_path / "screentime-zellij.db")
    core.SpanLog(db, "pane_spans", ("session", "pane_id", "class")).record(
        5, ("a", "terminal_1"), ("a", "terminal_1", "web")
    )
    log_call(db, 6)
    db.commit()
    assert report.fetch("here", 0) == {
        "pane_spans": [[5, 5, "a", "terminal_1", "web"]],
        "calls": [6],
    }


def test_fetch_remote(monkeypatch):
    calls = []

    class Done:
        stdout = '{"pane_spans": [[1, 2, "a", "terminal_1", "web"]], "calls": [1.5]}'

    def run(cmd, **kw):
        calls.append(cmd)
        return Done()

    monkeypatch.setattr(report.subprocess, "run", run)
    monkeypatch.setattr(report.socket, "gethostname", lambda: "here")
    assert report.fetch("there", 7.5) == {
        "pane_spans": [[1, 2, "a", "terminal_1", "web"]],
        "calls": [1.5],
    }
    assert calls == [
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=5",
            "there",
            "screentime",
            "zellij-log",
            "7.5",
        ]
    ]


@pytest.mark.parametrize(
    "seconds, text",
    [(0, "0:00:00"), (29.4, "0:00:29"), (61, "0:01:01"), (3600 * 25 + 5, "25:00:05")],
)
def test_duration(seconds, text):
    assert report.duration(seconds) == text
