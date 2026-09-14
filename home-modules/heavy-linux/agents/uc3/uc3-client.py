import os
import socket
import sys


def report(message):
    print(f"uc3ctl: {message}", file=sys.stderr)


def main():
    sock_path, seconds, *command = sys.argv[1:]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(int(seconds) or None)
    try:
        sock.connect(sock_path)
        # the broker runs ssh straight on our stdio; the socket only carries
        # the command in and the exit status back
        socket.send_fds(sock, [os.fsencode(" ".join(command))], [0, 1, 2])
        sock.shutdown(socket.SHUT_WR)
        status = b"".join(iter(lambda: sock.recv(64), b""))
    except TimeoutError:
        report(f"local timeout after {seconds}s (remote may still be running)")
        return 124
    except OSError as error:
        report(f"broker connection failed: {error}")
        return 1
    try:
        return int(status)
    except ValueError:
        report("protocol error: no exit status")
        return 1


sys.exit(main())
