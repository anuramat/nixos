# runs the labeled cases through the decision model with the hostrun handler's
# questions, ../questions.json, and prints the misses and the confusion
# matrices of the combined verdict: destructive if any answer is, else unknown
# if any answer is, else safe;
# usage: python3 eval.py http://anuramat-bgm5:11344/v1/systemone
import collections
import concurrent.futures
import json
import pathlib
import sys
import urllib.request

from cases import DISKS, HELDOUT, TUNED

url = sys.argv[1]
questions = json.loads(
    (pathlib.Path(__file__).parent.parent / "questions.json").read_text()
)


def ask(script):
    body = json.dumps({"state": script, "questions": questions}).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/json"})
    answers = json.load(urllib.request.urlopen(req))["answers"]
    return {q: a["choice"][0] for q, a in answers.items()}


def run(name, cases):
    with concurrent.futures.ThreadPoolExecutor(4) as ex:
        answers = list(ex.map(lambda c: ask(c[1]), cases))
    conf = collections.Counter()
    print(f"== {name}")
    for (want, script), a in zip(cases, answers):
        got = next((x for x in "du" if x in a.values()), "s")
        conf[want, got] += 1
        if got != want:
            print(f"want={want} got={got} {a} {script!r:.90}")
    print("rows: want, columns: got\n     d   s   u")
    for w in "dsu":
        print(w + "".join(f"{conf[w, g]:4}" for g in "dsu"))
    print(f"accuracy: {sum(conf[x, x] for x in 'dsu')}/{len(cases)}\n")


run("tuned", TUNED)
run("held out", HELDOUT)
run("disks", DISKS)
