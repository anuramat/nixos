# host side of a relay; one instance per connection (systemd Accept=yes):
# logs the call, runs the handler on the caller's stdio, stops it once the
# caller hangs up, and passes its exit status back
import contextlib
import os
import select
import socket
import struct
import subprocess
import sys
import time

sock = socket.socket(fileno=0)


def caller(pid):
    # the argv0 that sandbox.nix gives bwrap, see fleet-status
    while pid:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            argv0 = f.read().split(b"\0")[0].decode()
        if argv0.startswith("agent-sandbox:"):
            return argv0.removeprefix("agent-sandbox:")
        with open(f"/proc/{pid}/stat") as f:
            pid = int(f.read().rsplit(")", 1)[1].split()[1])
    return "unsandboxed"


creds = sock.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12)
who = caller(struct.unpack("3i", creds)[0])
data, fds, _, _ = socket.recv_fds(sock, 65536, 3)
while chunk := sock.recv(65536):
    data += chunk
cwd, cmd = os.fsdecode(data).split("\0", 1)
print(who, repr(cwd), repr(cmd), file=sys.stderr)
started = time.monotonic()
handler = subprocess.Popen(
    [*sys.argv[1:], cmd],
    stdin=fds[0],
    stdout=fds[1],
    stderr=fds[2],
    env=os.environ | {"RELAY_CALLER": who, "RELAY_CWD": cwd},
)
for fd in fds:
    os.close(fd)
poll = select.poll()
poll.register(sock, 0)  # a hangup is reported even though it's not asked for
poll.register(os.pidfd_open(handler.pid), select.POLLIN)
if sock.fileno() in dict(poll.poll()):
    print("caller gone, stopping the handler", file=sys.stderr)
    handler.terminate()
rc = handler.wait()
rc = rc if rc >= 0 else 128 - rc  # killed by a signal, as a shell reports it
print(f"rc={rc} dur={time.monotonic() - started:.0f}s", file=sys.stderr)
with contextlib.suppress(OSError):
    sock.sendall(b"%d\n" % rc)
