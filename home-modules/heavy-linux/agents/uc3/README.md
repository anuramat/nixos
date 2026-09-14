# uc3 relay — logged, keyless cluster shell for sandboxed agents

Gives the bwrap-sandboxed coding agents one command, `uc3ctl`, that runs
arbitrary commands on bwUniCluster 3.0. The cluster credential stays entirely
outside the sandbox and every command is logged on the host. There is no policy
on *what* runs — the relay only does auth, host-pinning, and logging. The agent
has a full cluster account; the cluster's own QOS/association limits are the
only resource backstop.

## Usage

```
uc3ctl [-t SECS] <command> [arg ...]
```

Runs `<command>` on uc3 and exits with its status. Semantics mirror
`ssh uc3 <command>`: the line is parsed by the cluster login shell, so quote to
control remote-vs-local expansion.

```sh
uc3ctl hostname
uc3ctl 'echo $HOME'                  # $HOME expands on the cluster
uc3ctl 'sbatch job.sh'
uc3ctl 'squeue -u $USER'
uc3ctl 'cat ~/agent/logs/<id>.out'

# upload: stdin is streamed to the remote command
tar c -C proj . | uc3ctl 'mkdir -p ~/agent/repo && tar x -C ~/agent/repo'

# binary download
uc3ctl 'cat ~/result.bin' > result.bin

# multiline script: pass a file on stdin, not a heredoc in the command argument
uc3ctl 'bash -s' < script.sh
```

The agent owns its cluster-side layout (repo location, `.sif` image, scratch
dirs) — nothing is baked in. Long synchronous commands hold a connection slot,
so `sbatch`/background long work and poll rather than blocking the relay. The
local timeout defaults to 300 seconds; raise it with `-t SECS` for large uploads
or long synchronous work, or use `-t 0` to rely only on the broker's one-hour
cap.

The request command must stay on one line. For multiline logic, put the script
in a file and use `uc3ctl 'bash -s' < script.sh`. Inline heredocs such as
`uc3ctl 'bash -s' <<'EOF'` and heredocs/newlines embedded in the command argument
are unsupported: they can leave the remote shell waiting for input.

## Architecture

```
uc3/
  default.nix   # uc3ctl package, systemd socket + broker service, ssh master service, log dir
  recv.py       # host side entry: takes the caller's stdio off the socket, runs the broker
  broker.sh     # host side; one instance per connection
  shim.sh       # installed as uc3ctl; agent + human entry point
  uc3-client.py # socket transport: sends the command with its stdio, returns the exit status
```

`uc3ctl` has zero authority: its shell shim validates the invocation,
redirects an interactive tty stdin to `/dev/null` (terminal input is never
consumed as an upload), and execs a Python client, which connects to
`$XDG_RUNTIME_DIR/uc3.sock`, sends the command line with its own
stdin/stdout/stderr attached (`SCM_RIGHTS`), and exits with the status it gets
back. systemd accepts each connection (`Accept=yes`) and runs one `uc3-recv`
per connection, which puts the caller's stdio in front of `uc3-broker`; the
broker logs the command and outcome, makes sure the shared ssh master
(`uc3-master.service`: started on demand, never restarted by systemd) is up,
then runs `ssh uc3 <cmd>` through it in BatchMode, straight on the caller's
stdio.

## Trust model

- The sandbox **shares the host network namespace**, so the agent can reach
  uc3's ssh port directly. The boundary is *credentials*, not connectivity:
  nothing inside the sandbox can authenticate to uc3.
- uc3 auth is non-interactive on the host: the service password and TOTP seed
  are agenix secrets (`uc3-pw.age`, `uc3-totp.age`), decrypted to
  `/run/agenix/*` owned by the user; `uc3-askpass` answers password/OTP prompts
  via `cat` / `oathtool --totp`, and only inside `uc3-master.service`: one TOTP
  serves every command until the connection drops, and systemd serializes the
  service's starts, so parallel cold starts cannot replay a code. The
  per-command ssh runs in BatchMode and never answers a prompt. None of this is
  reachable from the sandbox: no
  `~/.ssh`, no readable `/run/agenix`, and no ControlMaster socket bound in.
- The one unix socket is the only privileged channel, and it always logs before
  it runs — so the log is **complete**. The shared netns lets the agent reach
  the ssh port, but with no credential it cannot open its own session; there is
  no second, unlogged path to uc3.
- The destination is hardcoded to `uc3`: the agent supplies a command, never a
  host. The credential is cluster-only and cannot be extracted.
- The caller's stdio descriptors are its own: the broker only reads and writes
  them, so handing them over grants the sandbox nothing new.
- Full compromise of the sandbox yields a full uc3 shell — anything the cluster
  account can do, all logged — but never the host credential and never non-uc3
  access.

## Protocol

- **Request:** the command line, with the caller's stdin, stdout and stderr
  descriptors attached as ancillary data; the client then half-closes and the
  broker reads to EOF (the command may be up to the 128 KiB argv limit). The
  command must be **single-line** — use `uc3ctl 'bash -s' < script.sh` for
  multiline logic. Stdin is the upload channel: ssh reads it directly.
- **Response:** nothing but the exit status, as a decimal line at EOF; the
  client exits with it, or with 1 if it is missing. Remote stdout and stderr go
  straight to the caller's own descriptors, unmerged and byte-for-byte, so
  nothing is parsed or rewritten and binary downloads are safe by
  construction. `timeout` kill → 124; ssh rc 255 → a distinct "login failed"
  (the cluster refused the credentials; ssh's own message precedes it) or
  "cluster unreachable" message on stderr (ambiguous with a remote command
  that itself exits 255 — accepted). A refused login also trips a breaker:
  `~/.local/state/uc3/login-disabled` blocks every further login until a
  human removes it, so a caller's retry loop cannot lock the TOTP token (an
  existing master keeps serving). Early stdout close on the caller's side
  (`uc3ctl … | head`) is seen by ssh itself; the remote command's status is
  returned as usual.
- Broker errors are one line, `uc3: ERROR: …`, on the caller's stderr. The
  socket closes when the broker exits, so the client never hangs on a finished
  command.
- The client bounds its wait for the exit status to 300 seconds by default. A
  local expiry exits 124 with a distinct diagnostic; `-t 0` disables this bound
  without changing the broker's 3600-second cap.

## Logging

- The broker appends matching `START` and `END` lines to
  `$STATE_DIRECTORY/commands.log` (`StateDirectory=uc3` →
  `~/.local/state/uc3/commands.log`), outside any sandbox bind. Concurrent
  connections append under `flock`:

  ```text
  <timestamp>\tSTART\t<id>\t<command>
  <timestamp>\tEND\t<id>\trc=<code>\tdur=<seconds>s
  ```

- Only the command line is logged, not stdin/stdout. **Blind spot:** a remote
  shell (`uc3ctl 'bash -c …'` or `uc3ctl 'bash -s' < script.sh`) logs as one
  opaque top-level invocation, not the lines it runs. Top-level invocations are
  the audit unit.
- Broker diagnostics go to the caller's stderr; only `uc3-recv`'s own failures,
  before the stdio handoff, reach the journal: `journalctl --user -u
  'uc3-broker@*'`.

## Host dependencies

These live outside this directory; the relay depends on them:

- `../sandbox.nix` binds the socket into the sandbox rw:
  `--bind-try "$XDG_RUNTIME_DIR/uc3.sock" "$XDG_RUNTIME_DIR/uc3.sock"` — same
  path inside and out, so the shim is identical everywhere.
- `home-modules/base/default.nix` provides the `uc3` ssh entry with
  `ControlMaster auto`, `ControlPath ~/.ssh/cm-%r@%h-%p`, `ControlPersist yes`,
  `ServerAliveInterval 60`, `NumberOfPasswordPrompts 1`, plus the interactive
  `uc3` script (which cannot
  authenticate from inside the sandbox).
- agenix secrets `uc3-pw.age`, `uc3-totp.age` and the `uc3-askpass` helper.

## Verifying

1. After `home-manager switch`, `uc3-broker.socket` is active and the socket is
   mode 0600.
2. Host: `uc3ctl hostname` works (first call mints a TOTP and starts
   `uc3-master.service`; repeat is instant).
3. Inside the sandbox: `uc3ctl hostname` works and is logged host-side;
   `ssh uc3` hits a prompt it cannot answer; `cat /run/agenix/uc3-totp` and
   `uc3-askpass OTP` fail; no `~/.ssh` and **no ControlMaster socket** are
   visible. The CM-socket check is load-bearing — if it leaked, the agent could
   `ssh uc3` directly and bypass the log.
4. A nonzero remote command makes `uc3ctl` exit with the same code; a >300 s
   call needs an explicit larger `-t`, while a >1 h synchronous command is
   killed by the broker and reports 124.
5. Network down: `uc3ctl 'squeue'` → "cluster unreachable", no hang, no prompt.
   Wrong credentials: "login failed" once, then "logins disabled" without
   touching the cluster until `login-disabled` is removed.
6. A binary `cat` download matches the remote file's byte count and SHA-256;
   `uc3ctl 'echo a; sleep 5; echo b'` prints `a` immediately;
   `uc3ctl 'echo out; echo err >&2' 2>/dev/null` prints only `out`.
