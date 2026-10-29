"""Shared by both trackers: config, the decision model, rate limiting, the
classification cache and span storage."""

import base64
import hashlib
import json
import os
import sqlite3
import sys
import time
import urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path

TICK = 2  # s between span updates
GAP = 2 * TICK  # a longer pause between updates splits a span
FIRST_RECHECK = 30  # s
LAST_RECHECK = 300  # s
# span tables: name and columns after (start, end); the screen tracker's
# rows have either a class or a pane
SPANS = "spans", ("class", "pane")
PANE_SPANS = "pane_spans", ("session", "pane_id", "class")


def config_path():
    base = os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config"
    return Path(base) / "screentime" / "config.json"


def state_path(name):
    base = os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state"
    return Path(base) / name


def load_config(path=None):
    return json.loads(Path(path or config_path()).read_text())


def connect(path):
    db = sqlite3.connect(path)
    # so that the report can read while a tracker writes
    db.execute("pragma journal_mode=wal")
    return db


def classify(cfg, state, image=None, post=None):
    """(class, confidence) of the decision model's answer; image is JPEG bytes."""
    criteria = {c["name"]: c["criteria"] for c in cfg["classes"]}
    media = []
    if image is not None:
        data = base64.b64encode(image).decode()
        media.append({"type": "image", "data": "data:image/jpeg;base64," + data})
    body = {
        "state": state,
        "media": media,
        "questions": {
            "class": {
                "type": "choice",
                "instructions": cfg["instructions"],
                "criteria": criteria,
            }
        },
    }
    answer = (post or http_post)(cfg["url"], body)["answers"]["class"]
    if answer["choice"] not in criteria:
        raise ValueError(f"not a class: {answer['choice']!r}")
    return answer["choice"], answer["confidence"]


def http_post(url, body):
    req = urllib.request.Request(
        url, json.dumps(body).encode(), {"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


@dataclass
class Answer:
    input_kind: str  # what the model was given, e.g. "title" or "title+screenshot"
    image: bool
    cls: str
    confidence: float
    latency: float


def ask(input_kind, cfg, state, image=None, post=None):
    """classify() as an Answer, timed."""
    t = time.monotonic()
    cls, confidence = classify(cfg, state, image, post)
    return Answer(input_kind, image is not None, cls, confidence, time.monotonic() - t)


class Bucket:
    """Token bucket: rate tokens per minute, up to burst; charges may overdraw it."""

    def __init__(self, rate, burst, now):
        self.rate, self.burst = rate / 60, burst
        self.tokens, self.t = burst, now

    def _fill(self, now):
        self.tokens = min(self.burst, self.tokens + (now - self.t) * self.rate)
        self.t = now

    def ready(self, now):
        self._fill(now)
        return self.tokens >= 1

    def charge(self, cost, now):
        self._fill(now)
        self.tokens -= cost


@dataclass
class Span:
    rowid: int
    value: tuple
    target: object
    end: float


class SpanLog:
    """Rows of (start, end, *cols) in a table. Each series (e.g. a pane) has at
    most one open row, which record() extends while the value stays the same
    and the updates keep coming, and closes otherwise. Rows whose class is
    still being classified are recorded as "pending" with their target, and
    resolve() fills them in."""

    def __init__(self, db, table, cols):
        self.db, self.table, self.cols = db, table, cols
        db.execute(
            f"create table if not exists {table} (start real, end real, {', '.join(cols)})"
        )
        db.execute(f"create index if not exists {table}_end on {table} (end)")
        self.open = {}  # series -> Span
        self.pending = defaultdict(list)  # target -> rowids

    def record(self, now, series, value=None, target=None):
        """value is a tuple of the cols, or None to record nothing."""
        span = self.open.pop(series, None)
        if span and now - span.end < GAP:
            self.db.execute(
                f"update {self.table} set end = ? where rowid = ?", (now, span.rowid)
            )
            if (span.value, span.target) == (value, target):
                span.end = now
                self.open[series] = span
                return
        if value is None:
            return
        cur = self.db.execute(
            f"insert into {self.table} values ({', '.join('?' * (2 + len(self.cols)))})",
            (now, now, *value),
        )
        self.open[series] = Span(cur.lastrowid, value, target, now)
        if target is not None:
            self.pending[target].append(cur.lastrowid)

    def resolve(self, target, cls):
        rowids = self.pending.pop(target, [])
        self.db.executemany(
            f"update {self.table} set class = ? where rowid = ?",
            [(cls, r) for r in rowids],
        )
        i = self.cols.index("class")
        for span in self.open.values():
            if span.target == target:
                span.value = span.value[:i] + (cls,) + span.value[i + 1 :]
                span.target = None


@dataclass
class Entry:
    cls: str
    interval: float = FIRST_RECHECK
    due: float = field(default=0)


def classification_log(db):
    """Creates the log of answered model calls, one row per call."""
    db.execute(
        "create table if not exists classifications"
        " (t real, target text, input_kind text, class text, confidence real)"
    )


def call_times(db, since):
    """When the answered model calls after since were made."""
    classification_log(db)
    return [
        t for (t,) in db.execute("select t from classifications where t > ?", (since,))
    ]


def target_text(key):
    return "/".join(map(str, key))


class Engine:
    """Classifies one target at a time, in a worker thread, and caches each
    target's class until its recheck is due. A job is a function returning a
    list of Answers, the last of which decides the class."""

    def __init__(self, cfg, db, spans, rate, burst, text_cost, now, submit=None):
        self.cfg, self.db, self.spans = cfg, db, spans
        self.bucket = Bucket(rate, burst, now)
        # a text-only call's cost relative to a call with an image; measured
        # from the latencies once both kinds have been seen
        self.text_cost = text_cost
        self.latency = {}  # image: bool -> moving average, s
        self.cache = {}  # key -> Entry
        self.job = None  # (key, future)
        self.submit = submit or ThreadPoolExecutor(1).submit
        classification_log(db)

    def cls(self, key):
        entry = self.cache.get(key)
        return entry and entry.cls

    def due(self, key, now):
        """Whether key should be classified now: it's never been, or its recheck
        is due, and nothing else is being classified, and a token is available."""
        entry = self.cache.get(key)
        return (
            self.job is None
            and (entry is None or now >= entry.due)
            and self.bucket.ready(now)
        )

    def start(self, key, job):
        self.job = (key, self.submit(job))

    def drop(self, pred):
        for key in [k for k in self.cache if pred(k)]:
            del self.cache[key]

    def poll(self, now):
        if self.job is None or not self.job[1].done():
            return
        key, future = self.job
        self.job = None
        try:
            answers = future.result()
        except Exception as e:  # unreachable, an error, or a bad answer
            print(f"classifying {target_text(key)!r} failed: {e!r}", file=sys.stderr)
            answers = []
        for a in answers:
            self._account(a, now)
            self.db.execute(
                "insert into classifications values (?, ?, ?, ?, ?)",
                (now, self._log_target(key), a.input_kind, a.cls, a.confidence),
            )
        cls = answers[-1].cls if answers else "unknown"
        entry = self.cache.get(key)
        if entry is None:
            entry = self.cache[key] = Entry(cls)
        else:
            # a failure keeps the interval, so it's retried at the next recheck
            if answers:
                entry.interval = (
                    min(2 * entry.interval, LAST_RECHECK)
                    if entry.cls == cls
                    else FIRST_RECHECK
                )
            entry.cls = cls
        entry.due = now + entry.interval
        self.spans.resolve(key, cls)

    def _account(self, a, now):
        old = self.latency.get(a.image)
        self.latency[a.image] = (
            a.latency if old is None else 0.8 * old + 0.2 * a.latency
        )
        if True in self.latency and False in self.latency:
            self.text_cost = min(1, self.latency[False] / self.latency[True])
        self.bucket.charge(1 if a.image else self.text_cost, now)

    def _log_target(self, key):
        text = target_text(key)
        if self.cfg["calibration"]:
            return text
        return hashlib.sha256(text.encode()).hexdigest()
