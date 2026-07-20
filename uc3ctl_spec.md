# uc3ctl v2 — replace the socat pipeline with a Python socket client

Target: `/etc/nixos/home-modules/heavy-linux/agents/uc3/`. Follow-up to the
2026-07-20 WIP implementation (commits `8ef58774`/`6a2c5c91`/`d4bbad5b` in
/etc/nixos): the trailer protocol, broker changes, and nix wiring from that
round are correct and stay; this spec replaces only the shim's transport
pipeline. Broker, wire protocol, and logging are untouched.

## Verified state (2026-07-20, live acceptance run)

Passing: exit-code propagation; byte-perfect 1 MB binary download (sha256
match, no base64); true streaming (first line arrives ~1 s into a 5 s
command); mid-stream `--uc3-exit:7--` passed through verbatim; a payload
*ending* in a fake trailer (`data--uc3-exit:9--`) delivered byte-exact with
rc 0; `-t` fires and `-t 0` disables — all under closed stdin.

**Blocking defect:** any call whose stdin is an open-but-idle pipe/socket
hangs indefinitely, and `-t` cannot save it. Mechanism (observed live):

1. socat's `-t 3700` keeps the process alive after the socket side closes,
   waiting on the still-open stdin direction — the transaction is over (all
   payload bytes delivered) but socat lingers.
2. When the local `timeout` then kills socat, bash still waits on the whole
   pipeline, and the left group's `cat` blocks in `read(stdin)` forever —
   it has nothing to write, so it never gets SIGPIPE or EOF.

This is also the mechanism behind the two field zombies of 2026-07-19/20
(the old shim shares the structure). The needed semantics — *response EOF
ends the transaction regardless of request-side state* — is an asymmetry
one socat process cannot express: `-t` must stay ≥ remote runtime for
uploads (stdin EOFs first, response arrives much later), so it cannot be
small, and while stdin is open socat will not exit on its own.

## The change

One Python program, `uc3-client.py` (absorbing `trailer.py` — its
hold-back scanning logic is verified correct and moves over verbatim),
owns the whole transaction. The shim shrinks to help text, `-t` parsing,
the socket-existence check, the tty-stdin guard, and `exec uc3-client`.

Client behavior:

- **Connect** to `$XDG_RUNTIME_DIR/uc3.sock` (path via argv or env);
  connect failure → `uc3ctl: broker socket missing/refused: …` on stderr,
  exit 1.
- **Send** the command line (argv joined with spaces + `\n`) first.
- **Request pump**: a daemon thread copies stdin → socket
  (`os.read(0, 64k)` / `sendall`); on stdin EOF it calls
  `sock.shutdown(SHUT_WR)` and exits. Uploads are unchanged; after
  `SHUT_WR` the client keeps receiving for as long as the remote runs
  (this replaces the old `-t 3700` purpose). Socket errors in the pump
  (broker gone mid-upload) end the thread quietly — the main loop reports.
- **Response loop** (main thread): socket → stdout with the existing
  suffix-aware hold-back scan (≤ 32 bytes withheld only while they could
  still be a trailer; both trailer forms, with and without trailing `\n`,
  accepted for old-broker compat).
- **On response EOF**: parse the held tail. Trailer present → flush
  payload remainder, `sys.exit(rc)` — **the process exits immediately no
  matter what stdin is doing** (daemon thread dies with the interpreter);
  this is the whole point. No trailer → flush everything,
  `uc3ctl: protocol error: missing exit trailer` on stderr, exit 1.
- **Timeout**: `-t SECS` (default 300, `0` = unbounded) via
  `signal.alarm` in the main thread; on fire:
  `uc3ctl: local timeout after SECSs (remote may still be running)` on
  stderr, exit 124. This is now a genuine whole-transaction wall clock —
  no leg is outside it. Broker-side 124 (1 h remote cap) keeps its own
  message, so the two remain distinguishable.
- **Early stdout close** (caller did `| head`): `BrokenPipeError` →
  close the socket, exit 141 (SIGPIPE convention).
- rc is returned as the client's **exit code** — the fd-3 status file,
  the stderr capture file, `mktemp`, and the trap in the shim are all
  deleted. Client stderr goes straight to the caller.

`default.nix`: build `uc3-client` with `writers.writePython3Bin` (stdlib
only: `socket`, `threading`, `signal`, `os`, `sys`, `re`); shim
`runtimeInputs` drops `socat` and the separate trailer filter. Broker
untouched. `trailer.py` is deleted after its logic moves.

Keep the shim's tty guard (`[ ! -t 0 ] || exec </dev/null`): no longer
needed for hang-safety, but it stops an interactive call from eating
terminal input as "upload".

## Acceptance

All previous criteria, rerun:

- exit codes: `uc3ctl false` → 1, `uc3ctl 'exit 42'` → 42;
- binary: `uc3ctl 'cat big.bin' > f` sha256-matches remote; 1 MB and
  ~100 B sizes;
- streaming: first line of `uc3ctl 'echo a; sleep 4; echo b'` arrives
  < 2 s;
- trailer collisions: `printf -- "mid --uc3-exit:7-- stream\nmore\n"`
  verbatim rc 0; `printf -- "data--uc3-exit:9--"` byte-exact rc 0;
- upload: `tar c … | uc3ctl 'tar x -C …'` round-trips; and an upload
  whose remote keeps running after stdin EOF
  (`uc3ctl 'cat > /tmp/f; sleep 10; echo done' < smallfile`) completes
  with `done`;
- timeout: `uc3ctl -t 5 'sleep 30'` → 124, message, ~5 s wall;
  `uc3ctl -t 0 'sleep 5'` → 0.

New, the defect reproducers — the reason for v2:

- **open-idle stdin**: `uc3ctl 'head -c 1000 /dev/urandom' < <(sleep 60) > f`
  completes in seconds with 1000 bytes, exit 0, and
  `pgrep -f 'uc3-client|socat|uc3ctl'` is empty immediately after —
  no lingering processes while the `sleep 60` is still alive;
- same with the harness-style socket stdin if reproducible, and with a
  tty (guard path);
- remote-holds-stdout zombie:
  `uc3ctl -t 10 'nohup sleep 60 >/dev/null 2>&1 & echo hi'` prints `hi`
  and the local process is gone — by response-EOF if ssh closes, by the
  10 s alarm at worst.

## Non-goals (unchanged from v1)

No verb system; no rate limiting; no auth/trust-model changes; `--get`/
`--put` stay optional and unimplemented (plain redirection now covers
transfers); broker protocol and START/END logging stay exactly as
implemented.
