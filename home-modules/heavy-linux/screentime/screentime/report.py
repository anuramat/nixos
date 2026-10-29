"""The report: the screen tracker's spans, with each pane span replaced by the
pane's classes, as a table of time per day and class, and the number of
answered model calls per day, of the screen tracker and the zellij trackers
it reads."""

import json
import socket
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta

from . import core


def zellij_log(db, since):
    """The zellij tracker's rows ending after since, and its model calls since
    then, JSON-able."""
    core.SpanLog(db, *core.PANE_SPANS)  # the table, if the tracker hasn't run yet
    pane_spans = db.execute(
        "select start, end, session, pane_id, class from pane_spans where end > ?",
        (since,),
    )
    return {
        "pane_spans": [list(r) for r in pane_spans],
        "calls": core.call_times(db, since),
    }


def fetch_local(since):
    return zellij_log(core.connect(core.state_path("screentime-zellij.db")), since)


def fetch_remote(host, since):
    out = subprocess.run(
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=5",
            host,
            "screentime",
            "zellij-log",
            str(since),
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=60,
    ).stdout
    return json.loads(out)


def fetch(host, since):
    return (
        fetch_local(since)
        if host == socket.gethostname()
        else fetch_remote(host, since)
    )


def split_days(start, end):
    """(date, seconds) pieces of [start, end), split at local midnights."""
    t = start
    while t < end:
        day = datetime.fromtimestamp(t).date()
        midnight = datetime.combine(day + timedelta(days=1), datetime.min.time())
        piece_end = min(end, midnight.timestamp())
        yield day, piece_end - t
        t = piece_end


def gaps(start, end, intervals):
    """The parts of [start, end) not covered by intervals, which don't overlap."""
    t = start
    for a, b in sorted(intervals):
        if a > t:
            yield t, min(a, end)
        t = max(t, b)
        if t >= end:
            return
    if t < end:
        yield t, end


def totals(spans, pane_rows, since):
    """(date, class) -> seconds. spans: (start, end, class, pane) rows;
    pane_rows: host -> pane_spans of zellij_log(), or None if it couldn't be read."""
    by_pane = {}  # (host, session, pane_id) -> [(start, end, class)]
    for host, rows in pane_rows.items():
        for start, end, session, pane_id, cls in rows or []:
            by_pane.setdefault((host, session, pane_id), []).append((start, end, cls))
    out = defaultdict(float)

    def add(start, end, cls):
        for day, s in split_days(max(start, since), end):
            out[day, "unknown" if cls in (None, "pending") else cls] += s

    for start, end, cls, pane in spans:
        if pane is None:
            add(start, end, cls)
            continue
        host, rest = pane.split("/", 1)
        session, pane_id = rest.rsplit("/", 1)
        covered = []
        for a, b, c in by_pane.get((host, session, pane_id), []):
            lo, hi = max(a, start), min(b, end)
            if lo < hi:
                add(lo, hi, c)
                covered.append((lo, hi))
        for a, b in gaps(start, end, covered):
            add(a, b, None)
    return out


def calls_per_day(times):
    return Counter(datetime.fromtimestamp(t).date() for t in times)


def table(cfg, out, calls):
    """out: (date, class) -> seconds; calls: date -> model calls."""
    classes = [c["name"] for c in cfg["classes"]] + ["locked", "unknown"]
    classes = [c for c in classes if any(cls == c for _, cls in out)]
    days = sorted({day for day, _ in out} | set(calls))
    rows = [["day", *classes, "total", "calls"]]
    for day in days:
        values = [out.get((day, c), 0) for c in classes]
        rows.append(
            [
                day.isoformat(),
                *map(duration, values),
                duration(sum(values)),
                str(calls.get(day, 0)),
            ]
        )
    widths = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
    return "\n".join(
        "  ".join(
            cell.ljust(w) if i == 0 else cell.rjust(w)
            for i, (cell, w) in enumerate(zip(r, widths))
        )
        for r in rows
    )


def duration(seconds):
    s = round(seconds)
    return f"{s // 3600}:{s // 60 % 60:02}:{s % 60:02}"


def main(cfg, since, fetch=fetch):
    db = core.connect(core.state_path("screentime.db"))
    core.SpanLog(db, *core.SPANS)  # the table, if the tracker hasn't run yet
    spans = db.execute(
        "select start, end, class, pane from spans where end > ?", (since,)
    ).fetchall()
    calls = core.call_times(db, since)
    pane_rows = {}
    # this host's zellij tracker too, for its calls
    hosts = {pane.split("/", 1)[0] for *_, pane in spans if pane} | {
        socket.gethostname()
    }
    for host in sorted(hosts):
        try:
            log = fetch(host, since)
        except Exception as e:
            print(f"{host}: {e!r}; its panes are unknown", file=sys.stderr)
            pane_rows[host] = None
            continue
        pane_rows[host] = log["pane_spans"]
        calls += log["calls"]
    print(table(cfg, totals(spans, pane_rows, since), calls_per_day(calls)))
