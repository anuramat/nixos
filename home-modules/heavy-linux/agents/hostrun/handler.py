# the hostrun relay's handler, see ../relay
import atexit
import contextlib
import os
import select
import shlex
import signal
import socket
import subprocess
import sys
import time

from systemd import journal

prompt, *prompt_hosts, cmd = sys.argv[1:]
host = socket.gethostname()
cwd = os.environ["RELAY_CWD"]
who = f"{os.environ['RELAY_CALLER']} @ {host}"
# stderr is the requester's, so the prompts report to the journal instead
log = journal.stream("hostrun")
prompts = []  # every one started, to withdraw them at the end


def ask(h, request):
    # like fleet-status: this host directly, the others over ssh, which drops a
    # host after 90s of silence; the request ends with a NUL, then stdin carries
    # heartbeats, and closing it withdraws the prompt
    cmd = [prompt]
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
        ]
    # unbuffered, so that a write to a dead prompt leaves nothing to flush
    p = subprocess.Popen(
        cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log, bufsize=0
    )
    with contextlib.suppress(BrokenPipeError):
        p.stdin.write(request + b"\0")
    prompts.append(p)
    return p


def first_answer(request):
    # the first line from any prompt; every 30s, the prompts get a heartbeat,
    # and hosts without one (asleep, offline, logged out, dropped) get another
    # try
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
            if answer := live[fd][1].stdout.readline().strip():
                return answer
            poll.unregister(fd)
            del live[fd]


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


def fail(rc, message):
    print(f"hostrun: {message}", file=sys.stderr)
    sys.exit(rc)


# the relay's signal that the requester is gone; exits through settle()
signal.signal(signal.SIGTERM, lambda *_: sys.exit())
if not os.path.isdir(cwd):
    fail(1, f"{cwd} doesn't exist outside the sandbox")

answer = first_answer(f"{who}\ncwd: {shlex.quote(cwd)}\n$ {cmd}\n".encode())
withdraw()
if answer == b"deny":
    fail(77, "denied by the user")
if answer != b"allow":
    fail(255, f"unexpected answer {answer!r}, see the journal on {host}")
sys.exit(
    subprocess.run(["bash", "-c", cmd], cwd=cwd, stdin=subprocess.DEVNULL).returncode
)
