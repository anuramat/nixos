# the hostrun relay's handler, see ../relay
import atexit
import contextlib
import json
import os
import select
import shlex
import signal
import socket
import subprocess
import sys
import time
import urllib.request

from systemd import journal

# the prompt hosts are comma-separated; questions are the decision model's
# questions about the command, see questions.json; target is the -h host, or
# empty; root is non-empty for -r
prompt, prompt_hosts, decision_url, questions, desc, target, root, cmd = sys.argv[1:]
prompt_hosts = prompt_hosts.split(",")
host = socket.gethostname()
cwd = os.environ["RELAY_CWD"]
who = f"{os.environ['RELAY_CALLER']} @ {host}"
# stderr is the requester's, so the prompts report to the journal instead
log = journal.stream("hostrun")
prompts = []  # every one started, to withdraw them at the end


def ask(h, request):
    # like fleet-probe: this host directly, the others over ssh, which drops a
    # host after 90s of silence; the description, for the notification, the
    # request, for the review, and the root flag each end with a NUL, then
    # stdin carries heartbeats, and closing it withdraws the prompt; the
    # argument is this host, the one notify-forward routes the prompt from
    cmd = [prompt, host]
    if h != host:
        cmd = [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=5",
            "-o",
            "ServerAliveInterval=30",
            "-o",
            "ServerAliveCountMax=3",
            h,
            "hostrun-prompt",
            host,
        ]
    # unbuffered, so that a write to a dead prompt leaves nothing to flush
    p = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log, bufsize=0
    )
    with contextlib.suppress(BrokenPipeError):
        p.stdin.write(b"\0".join([desc.encode(), request, root.encode(), b""]))
    prompts.append(p)
    return p


def first_answer(request):
    # the first line from any prompt, without its newline; every 30s, the prompts get a heartbeat,
    # and hosts without one (asleep, offline, dropped) get another try
    poll = select.poll()
    live = {}  # stdout fd -> (host, prompt)
    tick = 0
    while True:
        if time.monotonic() >= tick:
            tick = time.monotonic() + 30
            for _, p in live.values():
                with contextlib.suppress(BrokenPipeError):
                    p.stdin.write(b"\n")
            for h in set(prompt_hosts) - {h for h, _ in live.values()}:
                p = ask(h, request)
                live[p.stdout.fileno()] = h, p
                poll.register(p.stdout, select.POLLIN)
        for fd, _ in poll.poll(max(0, tick - time.monotonic()) * 1000):
            # not stripped: the rest of the line after allow may be sudo's password
            if answer := live[fd][1].stdout.readline().removesuffix(b"\n"):
                return answer
            # gone: close its pipes and reap it, or each retry leaks them
            poll.unregister(fd)
            p = live.pop(fd)[1]
            prompts.remove(p)
            with p:
                pass


def withdraw():
    for p in prompts:
        p.stdin.close()  # withdraws the prompt, if it's still up


@atexit.register
def settle():
    # let the withdrawn prompts close their notifications before systemd stops
    # the unit and kills them
    withdraw()
    for p in prompts:
        p.wait()


def verdicts():
    # whether the command can destroy data in $HOME or on other disks, one line
    # per question, for the review; tested by eval/eval.py; the request waits
    # for it, so a decision model host that's asleep or offline only gets a few
    # seconds
    body = {"state": cmd, "questions": json.load(open(questions))}
    req = urllib.request.Request(
        decision_url, json.dumps(body).encode(), {"Content-Type": "application/json"}
    )
    try:
        answers = json.load(urllib.request.urlopen(req, timeout=10))["answers"]
    except Exception as e:
        return f" unavailable ({e})"
    return "".join(
        f"\n  {q}: {a['choice']} ({', '.join(f'{k} {v:.2f}' for k, v in a['probabilities'].items())})"
        for q, a in answers.items()
    )


def fail(rc, message):
    print(f"hostrun: {message}", file=sys.stderr)
    sys.exit(rc)


# the relay's signal that the requester is gone; exits through settle()
signal.signal(signal.SIGTERM, lambda *_: sys.exit())
run = ["bash", "-c", cmd]
if root:
    # -k: always reads the password, so that the command's stdin never gets it;
    # the user services' PATH may lack the wrappers, a login shell's doesn't
    sudo = "sudo" if target else "/run/wrappers/bin/sudo"
    run = [sudo, "-k", "-S", "-p", "", "--", *run]
where = f"cwd: {shlex.quote(cwd)}"
if target:
    # in the user's home there, as with a plain ssh
    run = ["ssh", "-o", "BatchMode=yes", "--", target, shlex.join(run)]
    where = f"ssh: {shlex.quote(target)}"
    cwd = None
elif not os.path.isdir(cwd):
    fail(1, f"{cwd} doesn't exist outside the sandbox")

# the first line is the notification's title
as_root = "\nas: root" if root else ""
request = f"{who}\ndescription: {desc}\n{where}{as_root}\ndecision model:{verdicts()}\n$ {cmd}\n"
answer, _, password = first_answer(request.encode()).partition(b" ")
withdraw()
if answer == b"deny":
    fail(77, "denied by the user")
if answer != b"allow":
    fail(255, f"unexpected answer {answer!r}, see the journal on {host}")
# sudo reads the password, then the command gets EOF, as with /dev/null
stdin = {"input": password + b"\n"} if root else {"stdin": subprocess.DEVNULL}
sys.exit(subprocess.run(run, cwd=cwd, **stdin).returncode)
