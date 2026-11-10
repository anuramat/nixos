# runs the labeled cases through the decision model with the hostrun handler's
# question, ../verdict.json, and prints the misses and the confusion matrices;
# usage: python3 eval.py http://anuramat-bgm5:11344/v1/systemone
import collections
import concurrent.futures
import json
import pathlib
import sys
import urllib.request

from cases import HELDOUT, TUNED

url = sys.argv[1]
question = json.loads(
    (pathlib.Path(__file__).parent.parent / "verdict.json").read_text()
)


def ask(script):
    body = json.dumps({"state": script, "questions": {"q": question}}).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))["answers"]["q"]


def run(name, cases):
    with concurrent.futures.ThreadPoolExecutor(4) as ex:
        answers = list(ex.map(lambda c: ask(c[1]), cases))
    conf = collections.Counter()
    print(f"== {name}")
    for (want, script), a in zip(cases, answers):
        got = a["choice"][0]
        conf[want, got] += 1
        if got != want:
            p = " ".join(f"{k[0]}={v:.2f}" for k, v in a["probabilities"].items())
            print(f"want={want} got={got} [{p}] {script!r:.90}")
    print("rows: want, columns: got\n     d   s   u")
    for w in "dsu":
        print(w + "".join(f"{conf[w, g]:4}" for g in "dsu"))
    print(f"accuracy: {sum(conf[x, x] for x in 'dsu')}/{len(cases)}\n")


run("tuned", TUNED)
run("held out", HELDOUT)
