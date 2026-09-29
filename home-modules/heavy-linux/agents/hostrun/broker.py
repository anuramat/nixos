# host side of hostrun; one instance per connection (systemd Accept=yes)
import atexit
import contextlib
import os
import select
import shlex
import socket
import struct
import subprocess
import sys
import time

prompt, *prompt_hosts = sys.argv[1:]
host = socket.gethostname()
sock = socket.socket(fileno=0)
prompts = []  # every one started, to withdraw them at the end


def sandbox(pid):
    # the argv0 that sandbox.nix gives bwrap, see fleet-status
    while pid:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            argv0 = f.read().split(b"\0")[0].decode()
        if argv0.startswith("agent-sandbox:"):
            return argv0.removeprefix("agent-sandbox:")
        with open(f"/proc/{pid}/stat") as f:
            pid = int(f.read().rsplit(")", 1)[1].split()[1])
    return "unsandboxed"


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
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)
    with contextlib.suppress(BrokenPipeError):
        p.stdin.write(request + b"\0")
    prompts.append(p)
    return p


def first_answer(request):
    # the first line from any prompt, or None once the requester is gone; every
    # 30s, the prompts get a heartbeat, and hosts without one (asleep, offline,
    # logged out, dropped) get another try
    poll = select.poll()
    poll.register(sock, 0)  # a hangup is reported even though it's not asked for
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
            if fd == sock.fileno():
                return None
            if answer := live[fd][1].stdout.readline().strip():
                return answer
            poll.unregister(fd)
            del live[fd]


@atexit.register
def settle():
    # let the withdrawn prompts close their notifications before systemd stops
    # the unit and kills them
    for p in prompts:
        p.wait()


def finish(rc, message=None):
    if message:
        os.write(err, f"hostrun: {message}\n".encode())
    print(f"rc={rc}", file=sys.stderr)
    sock.sendall(b"%d\n" % rc)
    sys.exit()


creds = sock.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12)
who = f"{sandbox(struct.unpack('3i', creds)[0])} @ {host}"
data, (out, err), _, _ = socket.recv_fds(sock, 65536, 2)
while chunk := sock.recv(65536):
    data += chunk
cwd, cmd = os.fsdecode(data).split("\0", 1)
print(who, repr(cwd), repr(cmd), file=sys.stderr)
if not os.path.isdir(cwd):
    finish(1, f"{cwd} doesn't exist outside the sandbox")

answer = first_answer(f"{who}\ncwd: {shlex.quote(cwd)}\n$ {cmd}\n".encode())
for p in prompts:
    p.stdin.close()  # withdraws the prompts that are still up
if answer is None:
    sys.exit("requester gone, not running")
if answer == b"deny":
    finish(77, "denied by the user")
if answer != b"allow":
    finish(255, f"unexpected answer {answer!r}, see the journal on {host}")
rc = subprocess.run(
    ["bash", "-c", cmd], cwd=cwd, stdin=subprocess.DEVNULL, stdout=out, stderr=err
).returncode
finish(rc)
