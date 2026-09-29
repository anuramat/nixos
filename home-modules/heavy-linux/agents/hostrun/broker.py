# host side of hostrun; one instance per connection (systemd Accept=yes)
import atexit
import os
import select
import shlex
import socket
import struct
import subprocess
import sys

prompt, *prompt_hosts = sys.argv[1:]
host = socket.gethostname()
sock = socket.socket(fileno=0)
prompts = {}


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
    # like fleet-status: this host directly, the others over ssh; the request
    # ends with a NUL, and closing stdin afterwards withdraws the prompt
    cmd = [prompt]
    if h != host:
        cmd = [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=5",
            h,
            "hostrun-prompt",
        ]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    p.stdin.write(request + b"\0")
    p.stdin.flush()
    return p


def first_answer():
    # the first line from any prompt (hosts that can't show one close stdout
    # without a line), or None once the requester is gone
    poll = select.poll()
    poll.register(sock, 0)  # a hangup is reported even though it's not asked for
    for fd in prompts:
        poll.register(fd, select.POLLIN)
    live = set(prompts)
    while live:
        for fd, _ in poll.poll():
            if fd == sock.fileno():
                return None
            poll.unregister(fd)
            live.discard(fd)
            if answer := prompts[fd].stdout.readline().strip():
                return answer
    return b""


@atexit.register
def settle():
    # let the withdrawn prompts close their notifications before systemd stops
    # the unit and kills them
    for p in prompts.values():
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

request = f"{who}\ncwd: {shlex.quote(cwd)}\n$ {cmd}\n".encode()
prompts = {p.stdout.fileno(): p for p in (ask(h, request) for h in prompt_hosts)}
answer = first_answer()
for p in prompts.values():
    p.stdin.close()  # withdraws the prompts that are still up
if answer is None:
    sys.exit("requester gone, not running")
if answer == b"deny":
    finish(77, "denied by the user")
if answer != b"allow":
    finish(255, f"no prompt could be shown, see the journal on {host}")
rc = subprocess.run(
    ["bash", "-c", cmd], cwd=cwd, stdin=subprocess.DEVNULL, stdout=out, stderr=err
).returncode
finish(rc)
