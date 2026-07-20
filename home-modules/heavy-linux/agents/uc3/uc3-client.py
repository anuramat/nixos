import os
import re
import signal
import socket
import sys
import threading


PREFIX = b"--uc3-exit:"


class LocalTimeout(Exception):
    pass


def write(fd, data):
    while data:
        written = os.write(fd, data)
        data = data[written:]


def report(message):
    print(f"uc3ctl: {message}", file=sys.stderr)


def possible_suffix(data):
    i = data.rfind(PREFIX)
    if i >= 0:
        after_prefix = i + len(PREFIX)
        rest = data[after_prefix:]
        digits = len(rest) - len(rest.lstrip(b"0123456789"))
        suffixes = (b"", b"-", b"--", b"--\n")
        if (digits or not rest) and rest[digits:] in suffixes:
            return i
    for length in range(min(len(data), len(PREFIX) - 1), 0, -1):
        if PREFIX.startswith(data[-length:]):
            return len(data) - length
    return len(data)


def pump_request(sock):
    try:
        while chunk := os.read(0, 65536):
            sock.sendall(chunk)
        sock.shutdown(socket.SHUT_WR)
    except OSError:
        pass


def receive_response(sock):
    pending = b""
    while chunk := sock.recv(65536):
        pending += chunk
        ready = max(possible_suffix(pending), len(pending) - 32)
        if ready:
            write(1, pending[:ready])
            pending = pending[ready:]

    match = re.fullmatch(rb"--uc3-exit:([0-9]+)--\n?", pending)
    if match:
        return int(match[1])

    write(1, pending)
    report("protocol error: missing exit trailer")
    return 1


def main():
    sock_path, seconds, *command = sys.argv[1:]
    seconds = int(seconds)

    def timeout(_signum, _frame):
        raise LocalTimeout

    signal.signal(signal.SIGALRM, timeout)
    signal.alarm(seconds)
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        try:
            sock.connect(sock_path)
        except OSError as error:
            report(f"broker socket missing/refused: {error}")
            return 1

        sock.sendall(os.fsencode(" ".join(command) + "\n"))
        pump = threading.Thread(target=pump_request, args=(sock,), daemon=True)
        pump.start()
        return receive_response(sock)
    except LocalTimeout:
        report(
            f"local timeout after {seconds}s "
            "(remote may still be running)"
        )
        return 124
    except BrokenPipeError:
        return 141
    except OSError as error:
        report(f"broker connection failed: {error}")
        return 1
    finally:
        signal.alarm(0)
        sock.close()


sys.exit(main())
