import base64
import hashlib

import pytest
from conftest import rows

from screentime import core


def test_classify_request(cfg, model):
    model.answers.append(("coding", 0.9))
    assert core.classify(cfg, {"a": "b"}, b"jpeg", model) == ("coding", 0.9)
    (body,) = model.requests
    assert body["state"] == {"a": "b"}
    assert body["media"] == [
        {
            "type": "image",
            "data": "data:image/jpeg;base64," + base64.b64encode(b"jpeg").decode(),
        }
    ]
    q = body["questions"]["class"]
    assert q["type"] == "choice"
    assert q["instructions"] == "Which class?"
    assert list(q["criteria"]) == ["nixos", "thesis", "coding", "chat", "web", "misc"]
    assert q["criteria"]["web"] == "web things"


def test_classify_without_image(cfg, model):
    model.answers.append(("web", 0.1))
    core.classify(cfg, "text", post=model)
    assert model.requests[0]["media"] == []


def test_classify_rejects_unknown_class(cfg, model):
    model.answers.append(("gaming", 1.0))
    with pytest.raises(ValueError):
        core.classify(cfg, {}, post=model)


def test_ask(cfg, model):
    model.answers.append(("web", 0.5))
    a = core.ask("title", cfg, {}, post=model)
    assert (a.input_kind, a.image, a.cls, a.confidence) == ("title", False, "web", 0.5)
    assert a.latency >= 0


def test_bucket():
    b = core.Bucket(rate=6, burst=2, now=0)  # a token per 10 s
    assert b.ready(0)
    b.charge(1, 0)
    b.charge(1, 0)
    assert not b.ready(0)
    assert not b.ready(9)
    assert b.ready(10)
    # never above burst
    assert b.ready(1000) and b.tokens == 2
    # overdrawn
    b.charge(3.5, 1000)
    assert not b.ready(1020)
    assert b.ready(1025)


def test_paths(monkeypatch, tmp_path):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path / "c"))
    monkeypatch.setenv("XDG_STATE_HOME", str(tmp_path / "s"))
    assert core.config_path() == tmp_path / "c" / "screentime" / "config.json"
    assert core.state_path("x.db") == tmp_path / "s" / "x.db"
    core.config_path().parent.mkdir(parents=True)
    core.config_path().write_text('{"a": 1}')
    assert core.load_config() == {"a": 1}


def test_connect_wal(tmp_path):
    db = core.connect(tmp_path / "x.db")
    assert db.execute("pragma journal_mode").fetchone() == ("wal",)


def spanlog(db):
    return core.SpanLog(db, "spans", ("class", "pane"))


def test_spans_extend_and_change(db):
    s = spanlog(db)
    s.record(0, (), ("web", None))
    s.record(2, (), ("web", None))
    s.record(3.5, (), ("chat", None))
    s.record(5, (), ("chat", None))
    assert rows(db, "spans") == [(0, 3.5, "web", None), (3.5, 5, "chat", None)]


def test_spans_gap_splits(db):
    s = spanlog(db)
    s.record(0, (), ("web", None))
    s.record(2, (), ("web", None))
    s.record(2 + core.GAP, (), ("web", None))  # e.g. a suspend
    assert rows(db, "spans") == [
        (0, 2, "web", None),
        (2 + core.GAP, 2 + core.GAP, "web", None),
    ]


def test_spans_none_closes(db):
    s = spanlog(db)
    s.record(0, (), ("web", None))
    s.record(1, (), None)
    s.record(2, (), None)
    s.record(3, (), ("web", None))
    assert rows(db, "spans") == [(0, 1, "web", None), (3, 3, "web", None)]


def test_spans_series_are_independent(db):
    s = core.SpanLog(db, "pane_spans", ("session", "pane_id", "class"))
    s.record(0, ("a", "terminal_1"), ("a", "terminal_1", "web"))
    s.record(0, ("a", "terminal_2"), ("a", "terminal_2", "chat"))
    s.record(2, ("a", "terminal_1"), ("a", "terminal_1", "web"))
    s.record(2, ("a", "terminal_2"), ("a", "terminal_2", "chat"))
    assert rows(db, "pane_spans") == [
        (0, 2, "a", "terminal_1", "web"),
        (0, 2, "a", "terminal_2", "chat"),
    ]


def test_spans_pending_resolve(db):
    s = spanlog(db)
    s.record(0, (), ("pending", None), "k")
    s.record(2, (), ("pending", None), "j")  # another target isn't merged
    s.record(4, (), ("pending", None), "k")
    s.resolve("k", "web")
    # the open row now has the class, and keeps being extended
    s.record(6, (), ("web", None))
    assert rows(db, "spans") == [
        (0, 2, "web", None),
        (2, 4, "pending", None),
        (4, 6, "web", None),
    ]
    assert dict(s.pending) == {"j": [2]}
    s.resolve("nothing", "web")


def engine(cfg, db, jobs, now=0, **kw):
    spans = spanlog(db)
    return core.Engine(
        cfg,
        db,
        spans,
        rate=6,
        burst=2,
        text_cost=0.5,
        now=now,
        submit=jobs.submit,
        **kw
    )


def answer(cls, image=False, confidence=0.9, latency=1.0):
    return core.Answer(
        "title+screenshot" if image else "title", image, cls, confidence, latency
    )


def test_engine_first_and_rechecks(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    assert e.cls("k") is None and e.due("k", 0)
    e.start("k", lambda: [answer("web")])
    assert not e.due("k", 0)  # busy
    e.poll(0)  # not done yet
    jobs.run()
    e.poll(1)
    assert e.cls("k") == "web"
    entry = e.cache["k"]
    assert (entry.interval, entry.due) == (30, 31)
    assert not e.due("k", 30)
    assert e.due("k", 31)
    # same class: the interval doubles, up to 5 min
    for t, interval in [(31, 60), (100, 120), (300, 240), (600, 300), (1000, 300)]:
        e.start("k", lambda: [answer("web")])
        jobs.run()
        e.poll(t)
        assert e.cache["k"].interval == interval
        assert e.cache["k"].due == t + interval
    # a change resets it
    e.start("k", lambda: [answer("chat")])
    jobs.run()
    e.poll(2000)
    assert (e.cls("k"), e.cache["k"].interval) == ("chat", 30)


def test_engine_last_answer_wins(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    e.start("k", lambda: [answer("web", confidence=0.3), answer("coding", image=True)])
    jobs.run()
    e.poll(0)
    assert e.cls("k") == "coding"
    assert rows(db, "classifications") == [
        (0, hashlib.sha256(b"k").hexdigest(), "title", "web", 0.3),
        (0, hashlib.sha256(b"k").hexdigest(), "title+screenshot", "coding", 0.9),
    ]


def test_engine_logs_plain_targets_during_calibration(cfg, db, jobs):
    cfg["calibration"] = True
    e = engine(cfg, db, jobs)
    e.start((31, "a title"), lambda: [answer("web")])
    jobs.run()
    e.poll(0)
    assert rows(db, "classifications")[0][1] == "31/a title"


def test_engine_failure(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    e.spans.record(0, (), ("pending", None), "k")

    def fail():
        raise OSError("unreachable")

    e.start("k", fail)
    jobs.run()
    e.poll(1)
    assert e.cls("k") == "unknown"
    assert e.cache["k"].due == 31
    assert rows(db, "spans") == [(0, 0, "unknown", None)]
    assert rows(db, "classifications") == []
    # a success after a failure: the class changed
    e.start("k", lambda: [answer("web")])
    jobs.run()
    e.poll(40)
    assert (e.cls("k"), e.cache["k"].interval) == ("web", 30)
    # a failure on a recheck keeps the interval
    for t in (70, 130):
        e.start("k", lambda: [answer("web")])
        jobs.run()
        e.poll(t)
    assert e.cache["k"].interval == 120
    e.start("k", fail)
    jobs.run()
    e.poll(300)
    assert (e.cls("k"), e.cache["k"].interval, e.cache["k"].due) == (
        "unknown",
        120,
        420,
    )


def test_engine_resolves_pending(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    e.spans.record(0, (), ("pending", None), "k")
    e.start("k", lambda: [answer("web")])
    jobs.run()
    e.poll(1)
    assert rows(db, "spans") == [(0, 0, "web", None)]


def test_engine_rate_limit(cfg, db, jobs):
    e = engine(cfg, db, jobs)  # 6 per min, burst 2
    for key in "ab":
        e.start(key, lambda: [answer("web", image=True)])
        jobs.run()
        e.poll(0)
    assert not e.due("c", 0)
    assert e.due("c", 10)


def test_engine_text_cost_measured(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    assert e.text_cost == 0.5
    e.start("a", lambda: [answer("web", latency=1.0)])
    jobs.run()
    e.poll(0)
    assert e.text_cost == 0.5  # no image call yet
    e.start("b", lambda: [answer("web", image=True, latency=4.0)])
    jobs.run()
    e.poll(0)
    assert e.text_cost == 0.25
    # moving averages
    e.start("c", lambda: [answer("web", latency=6.0)])
    jobs.run()
    e.poll(0)
    assert e.latency[False] == pytest.approx(2.0)
    assert e.text_cost == pytest.approx(0.5)
    # never more than an image call
    e.start("d", lambda: [answer("web", latency=100.0)])
    jobs.run()
    e.poll(0)
    assert e.text_cost == 1


def test_engine_drop(cfg, db, jobs):
    e = engine(cfg, db, jobs)
    for key in [(1, "a"), (2, "a"), ("firefox", "a")]:
        e.start(key, lambda: [answer("web")])
        jobs.run()
        e.poll(0)
    e.drop(lambda k: k[0] == 1)
    assert set(e.cache) == {(2, "a"), ("firefox", "a")}
