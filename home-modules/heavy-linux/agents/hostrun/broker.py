# host side of hostrun; one instance per connection (systemd Accept=yes)
import os
import select
import shlex
import socket
import struct
import subprocess
import sys

prompt_host, prompt = sys.argv[1:]
host = socket.gethostname()
sock = socket.socket(fileno=0)


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

request = f"{who}\ncwd: {shlex.quote(cwd)}\n$ {cmd}\n"
ask = [prompt]
if host != prompt_host:
    ask = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=5",
        prompt_host,
        "hostrun-prompt",
    ]
answer = subprocess.run(
    ask, input=request.encode(), stdout=subprocess.PIPE
).stdout.strip()
if answer == b"deny":
    finish(77, "denied by the user")
if answer != b"allow":
    finish(255, f"the prompt on {prompt_host} failed, see the journal on {host}")

# the requester may have given up while the user was deciding (e.g. a tool
# call timeout); poll reports a hangup even though it's not requested
poll = select.poll()
poll.register(sock, 0)
if poll.poll(0):
    sys.exit("requester gone, not running")
rc = subprocess.run(
    ["bash", "-c", cmd], cwd=cwd, stdin=subprocess.DEVNULL, stdout=out, stderr=err
).returncode
finish(rc)
