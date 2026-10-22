# Matches open issues of the NixOS security tracker against the runtime
# closures of the hosts built by nixpkgs-bump, and reports new hits via tgfy.
# usage: nixpkgs-cves STATE_DIR ROOTS_DIR RELEASE
# The first run only records the current hits; later runs report the
# difference. A package matches if the closure has the version the tracker
# triaged for the release branch (or master, for packages from unstable).
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://tracker.security.nixos.org/api/v1"


def get(url):
    while True:
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            # "Request was throttled. Expected available in N seconds."
            m = re.search(r"(\d+) second", e.read().decode())
            time.sleep(int(m.group(1)) + 1 if m else 10)


def open_issues():
    url = f"{API}/issues"
    while url:
        page = get(url.replace("http://", "https://"))
        yield from (
            i for i in page["results"] if i["github_issue_state"][1] == "OPENED"
        )
        url = page["next"]


def suggestion(cache, id):
    path = f"{cache}/{id}.json"
    if not os.path.exists(path):
        with open(f"{path}.tmp", "w") as f:
            json.dump(get(f"{API}/suggestions/{id}"), f)
        os.rename(f"{path}.tmp", path)
    with open(path) as f:
        return json.load(f)


def closure(root):
    # version -> names
    out = subprocess.run(
        ["nix", "path-info", "-r", root],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    versions = {}
    for path in out.split():
        m = re.match(r"[^-]+-(.+?)-(\d[^-]*)", os.path.basename(path))
        if m:
            versions.setdefault(m[2], set()).add(norm(m[1]))
    return versions


def norm(name):
    # openssl_3_5 -> openssl, gimp3 -> gimp, dbus-broker -> dbusbroker
    return re.sub(r"[_-]?\d+(_\d+)*$", "", name.lower()).replace("-", "")


def hits(issues, cache, closures, branches):
    for issue in issues:
        for id in issue["suggestions"]:
            s = suggestion(cache, id)
            for attr, pkg in (s.get("packages") or {}).items():
                name = norm(attr.split(".")[-1])
                for branch in branches:
                    b = pkg["branches"].get(branch)
                    if not b or b["status"] == "unaffected":
                        continue
                    for host, versions in closures.items():
                        if name in versions.get(b["version"], ()):
                            key = f"{host} {issue['code']} {name}"
                            yield key, (
                                f"{host}: {issue['code']} {attr} "
                                f"{b['version']} [{b['status']}], "
                                f"{s['cve_id']}: {s['description'][:120]}, "
                                f"{issue['github_issue_url']}"
                            )


def notify(text):
    subprocess.run(["tgfy"], input=f"nixpkgs-cves: {text}", text=True)


def main(state, roots, release):
    os.makedirs(f"{state}/suggestions", exist_ok=True)
    closures = {h: closure(f"{roots}/{h}") for h in os.listdir(roots)}
    branches = [f"release-{release}", "master"]
    found = dict(hits(open_issues(), f"{state}/suggestions", closures, branches))
    seen_path = f"{state}/seen"
    first = not os.path.exists(seen_path)
    seen = set() if first else set(open(seen_path).read().splitlines())
    new = [found[k] for k in sorted(found.keys() - seen)]
    summary = f"+{len(new)} new, {len(found)} open, {len(seen - found.keys())} resolved"
    with open(f"{seen_path}.tmp", "w") as f:
        f.write("".join(f"{k}\n" for k in sorted(found)))
    os.rename(f"{seen_path}.tmp", seen_path)
    if first:
        notify(f"initialized; {len(found)} open hits recorded")
    elif new or seen - found.keys():
        notify("\n\n".join([summary, *new]))


try:
    main(*sys.argv[1:])
except Exception as e:
    notify(f"failed: {e}")
    raise
