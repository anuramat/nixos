"""usage: screentime screen | zellij | report [--since WHEN] | zellij-log SINCE

screen and zellij run the trackers; report prints the time per day and class
since WHEN (`date -d` syntax, default 7 days ago); zellij-log prints the zellij
tracker's rows ending after SINCE (seconds since the epoch) and its model
calls since then as JSON, for the report on another host."""

import argparse
import json
import subprocess

from . import core, report, screen, zellij


def main():
    p = argparse.ArgumentParser(prog="screentime")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("screen")
    sub.add_parser("zellij")
    r = sub.add_parser("report")
    r.add_argument("--since", default="7 days ago")
    s = sub.add_parser("zellij-log")
    s.add_argument("since", type=float)
    args = p.parse_args()
    if args.cmd == "zellij-log":
        db = core.connect(core.state_path("screentime-zellij.db"))
        print(json.dumps(report.zellij_log(db, args.since)))
        return
    cfg = core.load_config()
    if args.cmd == "screen":
        screen.main(cfg)
    elif args.cmd == "zellij":
        zellij.main(cfg)
    else:
        since = subprocess.run(
            ["date", "-d", args.since, "+%s"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        report.main(cfg, float(since))
