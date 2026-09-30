# `relay-client NAME SECONDS CMD...`: sends the command and our cwd with our
# stdin, stdout and stderr attached; the handler runs straight on those, and
# the socket only carries the request in and the exit status back; SECONDS
# bounds the wait, 0 for no bound
import os
import socket
import sys

name, seconds, *cmd = sys.argv[1:]
if not cmd:
    sys.exit(f"usage: {name} CMD...")
runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
sock = socket.socket(socket.AF_UNIX)
sock.settimeout(int(seconds) or None)
try:
    sock.connect(f"{runtime}/{name}.sock")
    request = os.fsencode(os.getcwd() + "\0" + " ".join(cmd))
    socket.send_fds(sock, [request], [0, 1, 2])
    sock.shutdown(socket.SHUT_WR)
    status = b"".join(iter(lambda: sock.recv(64), b""))
except TimeoutError:
    print(f"{name}: timed out after {seconds}s", file=sys.stderr)
    sys.exit(124)
except OSError as error:
    sys.exit(f"{name}: relay connection failed: {error}")
sys.exit(int(status) if status else f"{name}: no exit status from the relay")
