# SPEC: uc3 relay — logged, keyless cluster shell for sandboxed agents

## Goal

Give the bwrap-sandboxed coding agents one command (`uc3ctl`) that runs
**arbitrary commands on bwUniCluster 3.0**, with the cluster credential
held entirely outside the sandbox and every command logged on the host.
There is no policy on *what* runs: the relay's only jobs are auth,
host-pinning, and logging.

This replaces the earlier guardrailed-verb broker. Gone: the verb
allowlist, `remote.sh`, remote sbatch generation, the flock/queue
one-job check, and the GPU/walltime/node caps. The agent now has a full
cluster account; the cluster's own QOS/association limits are the only
resource backstop. What remains is a thin authenticated logging relay
over one unix socket.

## Trust model

- The sandbox **shares the host network namespace**, so the agent can
  reach uc3's ssh port directly. The boundary is therefore *credentials*,
  not connectivity: nothing inside the sandbox can authenticate to uc3.
- uc3 auth is non-interactive on the host: the service password and TOTP
  seed are agenix secrets (`uc3-pw.age`, `uc3-totp.age`), decrypted to
  `/run/agenix/*` owned by the user; `uc3-askpass` answers password/OTP
  prompts via `cat` / `oathtool --totp`. A ControlMaster connection
  (config in `home-modules/default/default.nix`) amortizes one TOTP over
  the persist window. None of this is reachable from the sandbox: no
  `~/.ssh`, no readable `/run/agenix`, **and no ControlMaster socket
  bound in**.
- The only privileged channel is one unix socket, and it always logs
  before it runs. This is what makes the log **complete**: the socket is
  the *only* path from inside the sandbox to an authenticated uc3 session.
  The shared netns lets the agent reach the ssh port, but with no
  credential it cannot open its own session — so there is no second,
  unlogged way to reach uc3.
- Destination is hardcoded to `uc3`: the agent supplies a command, never
  a host. Access is cluster-only; the credential cannot be used against
  any other host and cannot be extracted.
- Full compromise of the sandbox yields a full uc3 shell — anything the
  cluster account can do, all logged — but never the host credential and
  never non-uc3 access. The old "≤ 1 job, 1 node, ≤ 1 GPU, capped
  walltime" guarantees no longer exist.

## Non-goals

- Any policy on commands, resources, or sbatch shape — the agent writes
  its own jobs and manages its own cluster-side layout (repo location,
  `.sif` image, scratch dirs). Nothing is baked.
- Tests, watchdog/queue-reality enforcement, poll/notify timers (the
  agent checks status itself and can notify via `tgfy`).
- Interactive PTY sessions; byte-exact binary stdout download (see
  Protocol); multiple clusters; hardening against host compromise.

## Layout

```
home-modules/heavy-linux/agents/uc3/
  default.nix   # uc3ctl package, systemd socket + service, log dir
  broker.sh     # host side, stdio; one instance per connection
  shim.sh       # installed as uc3ctl; agent + human entry point
```

`remote.sh` is deleted. There are no `replaceVarsWith` / `@token@`
constants any more (no `partition`/`sif`/`jobName`/`time`/`projectDir`):
the only fixed values are the ssh destination `uc3` and the host-side log
path. The two edits elsewhere are unchanged from the previous design:

- `home-modules/heavy-linux/agents/sandbox.nix`: add
  `--bind-try "$XDG_RUNTIME_DIR/uc3.sock" "$XDG_RUNTIME_DIR/uc3.sock"`
  to the bwrap invocation (rw bind). Same path inside and outside, so the
  shim is identical everywhere.
- `home-modules/default/default.nix`: the existing `uc3` ssh entry keeps
  `ControlMaster auto`, `ControlPath ~/.ssh/cm-%r@%h-%p`,
  `ControlPersist 4h`, `ServerAliveInterval 60`. The interactive `uc3`
  script is untouched.

## Protocol

- Request: one `\n`-terminated **command line** — the remote shell
  command — optionally followed by a **stdin payload** streamed after it.
  The broker reads the first line as the command and forwards everything
  after it as that command's stdin (so uploads work, e.g.
  `tar c … | uc3ctl 'tar x -C ~/agent/repo'`). Semantics mirror
  `ssh uc3 <args>`: the command string is parsed by the cluster login
  shell, so the agent must quote to control remote-vs-local expansion
  (`uc3ctl 'echo $HOME'` expands on the cluster; unquoted `$HOME` expands
  in the sandbox).
  - No charset or length restriction (the allowlist is gone). The command
    must be **single-line**: a literal newline in the command is not
    supported — use `;`, or run `bash -c '…'` remotely.
- Response: remote stdout+stderr (merged) streamed back, then a trailer
  line `--uc3-exit:<code>--`. The shim strips the trailer and exits with
  `<code>`; missing trailer → exit 1. `<code>` is the remote command's
  exit status; `timeout` kill → 124; ssh rc 255 → distinct "cluster
  unreachable" message (ambiguous with a remote command that itself exits
  255 — accepted).
  - Caveat: the trailer is in-band on stdout, so **binary stdout
    passthrough is unsupported** — a download whose bytes are not
    text-safe (or happen to contain the trailer) will corrupt. Download
    binary via base64 / `tar | base64`, or write a cluster file and fetch
    it encoded. Uploads (stdin) are unaffected.
- Errors from the broker itself are one line, `uc3: ERROR: …`, sent over
  the socket so the agent sees them. The broker **always** emits the
  trailer, including on timeout/deny, so the shim never hangs.

## Logging

- Before running, the broker appends one line — timestamp + the command
  line — to a host-side log **outside any sandbox bind**:
  `$STATE_DIRECTORY/commands.log` (systemd `StateDirectory=uc3` →
  `~/.local/state/uc3/commands.log`). Concurrent connections append
  atomically (O_APPEND of a single short line; `flock` if a line could
  exceed `PIPE_BUF`).
- Only the command line is logged, not stdin/stdout. Blind spot: a remote
  shell — `uc3ctl 'bash -c …'`, `uc3ctl bash` with a piped script — logs
  as the top-level invocation, not the individual lines it runs.
  Top-level invocations are the audit unit.
- The broker's own diagnostics also go to the journal
  (`StandardError=journal`); read with
  `journalctl --user -u 'uc3-broker@*'` or `tail -f` the log file.

## broker.sh

Stdio only; systemd runs one instance per connection. `set -euo
pipefail`, shellcheck-clean. Read the command line (guarding empty/EOF),
append it to the log, then run ssh with auth plumbing inherited:

```
IFS= read -r cmd || exit 0
printf '%s\t%s\n' "$(date -Is)" "$cmd" >>"$STATE_DIRECTORY/commands.log"
rc=0
SSH_ASKPASS=uc3-askpass SSH_ASKPASS_REQUIRE=force \
  timeout 3600 ssh -o ConnectTimeout=15 uc3 -- "$cmd" 2>&1 || rc=$?
[ "$rc" = 255 ] && echo "uc3: ERROR: cluster unreachable"
printf -- '--uc3-exit:%s--\n' "$rc"
```

The remaining socket bytes are ssh's stdin; `2>&1` puts remote stderr on
the socket too. **No `BatchMode`** — it disables askpass. `|| rc=$?`
keeps `set -e` from aborting before the trailer. `timeout 3600`: long
synchronous commands hold a connection slot (see `MaxConnections`), so
the agent should `sbatch`/background long work and poll rather than block
the relay.

## shim.sh (`uc3ctl`)

Zero authority. Send `"$*"` as the command line, then stream this
process's own stdin; strip the trailer and exit with its code:

```
{ printf '%s\n' "$*"; cat; } | socat - UNIX-CONNECT:"$XDG_RUNTIME_DIR/uc3.sock"
```

Socket absent or trailer missing → clear error, exit 1. No args (or
`help`) → print usage offline. Named `uc3ctl`, **not** `uc3`, to avoid
colliding with the existing interactive `uc3` ssh script (which is on
PATH but cannot authenticate from inside the sandbox anyway).

## default.nix

- `home.packages = [ uc3ctl ]`.
- `systemd.user.sockets.uc3-broker`: `ListenStream=%t/uc3.sock`,
  `SocketMode=0600`, `Accept=yes`, `MaxConnections=8`,
  `WantedBy=sockets.target`.
- `systemd.user.services."uc3-broker@"`: `StandardInput=socket`,
  `StandardOutput=socket`, `StandardError=journal`, `StateDirectory=uc3`,
  `ExecStart=<broker>`, `CollectMode=inactive-or-failed`.

## Manual acceptance checklist

1. `home-manager switch`; `uc3-broker.socket` active, socket mode 0600.
2. Host: `uc3ctl hostname` works (first call mints a TOTP via oathtool and
   establishes the ControlMaster; repeat call is instant).
3. Inside the sandbox: `uc3ctl hostname` works and is logged host-side;
   `ssh uc3` hits a prompt it cannot answer; **`cat /run/agenix/uc3-totp`
   and `uc3-askpass OTP` FAIL**; no `~/.ssh` and **no ControlMaster
   socket** visible inside. The CM-socket check is load-bearing: if it
   leaked, the agent could `ssh uc3` directly and bypass the log — mask
   it in sandbox.nix before relying on the boundary.
4. Inside: upload via
   `tar c -C proj . | uc3ctl 'mkdir -p ~/agent/repo && tar x -C ~/agent/repo'`;
   run `uc3ctl 'sbatch …'`, `uc3ctl 'squeue -u $USER'`,
   `uc3ctl 'cat ~/agent/logs/<id>.out'`; each appears in
   `~/.local/state/uc3/commands.log`.
5. A remote command that exits nonzero → `uc3ctl` exits with the same
   code; a >1 h synchronous command is killed at the `timeout` and
   reports 124.
6. Network down: `uc3ctl 'squeue'` → "cluster unreachable", no hang, no
   prompt.

## What "done" looks like

`home-manager switch` builds; the checklist passes once. Steady state:
agents run `uc3ctl <command>` for anything on uc3; auth happens
transparently on the host via agenix secrets + ControlMaster; every
command is logged host-side. The only guarantees are credential
isolation, cluster-only destination, and a complete command log — not
resource limits.
