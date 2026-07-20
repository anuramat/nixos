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
  default.nix   # uc3ctl package, systemd socket + service, log dir
  broker.sh     # host side, stdio; one instance per connection
  shim.sh       # installed as uc3ctl; agent + human entry point
  uc3-client.py # socket transport and binary-safe trailer handling
```

`uc3ctl` has zero authority: its shell shim validates the invocation and execs
a Python client, which connects to `$XDG_RUNTIME_DIR/uc3.sock`, sends the
command line followed by stdin, streams the response while retaining only a
possible EOF trailer, and exits with the remote status. Response EOF completes
the transaction even if stdin is still open. systemd
accepts each connection (`Accept=yes`) and runs one `uc3-broker` per
connection; the broker logs the command and outcome, then runs `ssh uc3 <cmd>` with the
auth plumbing it inherits on the host.

## Trust model

- The sandbox **shares the host network namespace**, so the agent can reach
  uc3's ssh port directly. The boundary is *credentials*, not connectivity:
  nothing inside the sandbox can authenticate to uc3.
- uc3 auth is non-interactive on the host: the service password and TOTP seed
  are agenix secrets (`uc3-pw.age`, `uc3-totp.age`), decrypted to
  `/run/agenix/*` owned by the user; `uc3-askpass` answers password/OTP prompts
  via `cat` / `oathtool --totp`. A ControlMaster connection amortizes one TOTP
  over the persist window. None of this is reachable from the sandbox: no
  `~/.ssh`, no readable `/run/agenix`, and no ControlMaster socket bound in.
- The one unix socket is the only privileged channel, and it always logs before
  it runs — so the log is **complete**. The shared netns lets the agent reach
  the ssh port, but with no credential it cannot open its own session; there is
  no second, unlogged path to uc3.
- The destination is hardcoded to `uc3`: the agent supplies a command, never a
  host. The credential is cluster-only and cannot be extracted.
- Full compromise of the sandbox yields a full uc3 shell — anything the cluster
  account can do, all logged — but never the host credential and never non-uc3
  access.

## Protocol

- **Request:** one `\n`-terminated command line, optionally followed by a stdin
  payload streamed after it. The broker reads the first line as the command and
  forwards the rest as that command's stdin (uploads). The command must be
  **single-line** — use `uc3ctl 'bash -s' < script.sh` for multiline logic.
- **Response:** remote stdout+stderr (merged) streamed back, then a trailer
  line `--uc3-exit:<code>--`. The client strips the trailer and exits with
  `<code>`; a missing trailer → exit 1. `timeout` kill → 124; ssh rc 255 → a
  distinct "cluster unreachable" message (ambiguous with a remote command that
  itself exits 255 — accepted).
- Stdout is binary-safe. A trailer-shaped byte sequence in the middle of output
  is ordinary payload; only one in the reserved EOF position is interpreted as
  protocol metadata.
- Broker errors are one line, `uc3: ERROR: …`, sent over the socket. The broker
  **always** emits the trailer, including on timeout/unreachable, so the client
  never hangs.
- The client bounds the complete local socket operation to 300 seconds by
  default. A local expiry exits 124 with a distinct diagnostic; `-t 0` disables
  this bound without changing the broker's 3600-second cap.

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
- Broker diagnostics go to the journal: `journalctl --user -u 'uc3-broker@*'`.

## Host dependencies

These live outside this directory; the relay depends on them:

- `../sandbox.nix` binds the socket into the sandbox rw:
  `--bind-try "$XDG_RUNTIME_DIR/uc3.sock" "$XDG_RUNTIME_DIR/uc3.sock"` — same
  path inside and out, so the shim is identical everywhere.
- `home-modules/default/default.nix` provides the `uc3` ssh entry with
  `ControlMaster auto`, `ControlPath ~/.ssh/cm-%r@%h-%p`, `ControlPersist 4h`,
  `ServerAliveInterval 60`, plus the interactive `uc3` script (which cannot
  authenticate from inside the sandbox).
- agenix secrets `uc3-pw.age`, `uc3-totp.age` and the `uc3-askpass` helper.

## Verifying

1. After `home-manager switch`, `uc3-broker.socket` is active and the socket is
   mode 0600.
2. Host: `uc3ctl hostname` works (first call mints a TOTP and establishes the
   ControlMaster; repeat is instant).
3. Inside the sandbox: `uc3ctl hostname` works and is logged host-side;
   `ssh uc3` hits a prompt it cannot answer; `cat /run/agenix/uc3-totp` and
   `uc3-askpass OTP` fail; no `~/.ssh` and **no ControlMaster socket** are
   visible. The CM-socket check is load-bearing — if it leaked, the agent could
   `ssh uc3` directly and bypass the log.
4. A nonzero remote command makes `uc3ctl` exit with the same code; a >300 s
   call needs an explicit larger `-t`, while a >1 h synchronous command is
   killed by the broker and reports 124.
5. Network down: `uc3ctl 'squeue'` → "cluster unreachable", no hang, no prompt.
6. A binary `cat` download matches the remote file's byte count and SHA-256;
   `uc3ctl 'echo a; sleep 5; echo b'` prints `a` immediately.
