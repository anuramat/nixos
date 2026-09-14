import os
import socket
import subprocess
import sys

# systemd hands us the connection as fd 0 (Accept=yes). The client sends the
# command line with its own stdin/stdout/stderr attached; the broker runs ssh
# straight on those, and the socket only carries the exit status back.
sock = socket.socket(fileno=0)
cmd, fds, _, _ = socket.recv_fds(sock, 65536, 3)
while chunk := sock.recv(65536):
    cmd += chunk
broker = subprocess.run(
    [sys.argv[1], os.fsdecode(cmd)], stdin=fds[0], stdout=fds[1], stderr=fds[2]
)
sock.sendall(b"%d\n" % broker.returncode)
