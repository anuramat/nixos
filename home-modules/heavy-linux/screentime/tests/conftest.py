import json
import sqlite3
from concurrent.futures import Future
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent / "fixtures"


def fixture(name):
    return (FIXTURES / name).read_text()


@pytest.fixture
def cfg():
    return {
        "url": "http://model/v1/systemone",
        "instructions": "Which class?",
        "classes": [
            {"name": n, "criteria": f"{n} things"}
            for n in ("nixos", "thesis", "coding", "chat", "web", "misc")
        ],
        "dirs": {
            "/etc/nixos": "nixos",
            "/home/u/thesis": "thesis",
            "/home/u/thesis/vendor/nix": "nixos",
        },
        "apps": {"org.telegram.desktop": "chat"},
        "threshold": 0.7,
        "calibration": False,
    }


@pytest.fixture
def db():
    return sqlite3.connect(":memory:")


class Model:
    """A fake decision model: answers from a queue, records the requests."""

    def __init__(self):
        self.answers = []
        self.requests = []

    def __call__(self, url, body):
        self.requests.append(body)
        a = self.answers.pop(0)
        if isinstance(a, Exception):
            raise a
        choice, confidence = a
        return {"answers": {"class": {"choice": choice, "confidence": confidence}}}


@pytest.fixture
def model():
    return Model()


class Jobs:
    """A fake executor: jobs run when run() is called, in order."""

    def __init__(self):
        self.queue = []

    def submit(self, fn):
        f = Future()
        self.queue.append((fn, f))
        return f

    def run(self):
        while self.queue:
            fn, f = self.queue.pop(0)
            try:
                f.set_result(fn())
            except Exception as e:
                f.set_exception(e)


@pytest.fixture
def jobs():
    return Jobs()


def rows(db, table):
    return db.execute(f"select * from {table} order by rowid").fetchall()


def json_fixture(name):
    return json.loads(fixture(name))
