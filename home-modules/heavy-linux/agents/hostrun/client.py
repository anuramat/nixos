import os
import socket
import sys

if len(sys.argv) < 2:
    sys.exit("usage: hostrun CMD...")
runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
sock = socket.socket(socket.AF_UNIX)
sock.connect(f"{runtime}/hostrun.sock")
# the command runs straight on our stdout and stderr; the socket only carries
# the request in and the exit status back
request = os.getcwd() + "\0" + " ".join(sys.argv[1:])
socket.send_fds(sock, [os.fsencode(request)], [1, 2])
sock.shutdown(socket.SHUT_WR)
status = b"".join(iter(lambda: sock.recv(64), b""))
sys.exit(int(status) if status else "hostrun: no exit status from the broker")
