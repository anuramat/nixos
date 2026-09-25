# list the units running under the agent user's systemd (`systemd-run --user`
# jobs, scopes, custom slices; agent hosts only), the current user's sandboxed
# agent sessions and live zellij sessions on the given hosts (default: all
# hosts), as
# `HOST<TAB>job<TAB>UNIT<TAB>ELAPSED<TAB>COMMAND`,
# `HOST<TAB>session<TAB>WRAPPER<TAB>CWD` and
# `HOST<TAB>zellij<TAB>SESSION<TAB>CLIENTS`; units are read from the
# world-readable cgroupfs, so it needs neither the agent's user bus nor its ssh
# key; the current host is queried directly instead of over ssh
{
  pkgs,
  lib,
  inputs,
}:
let
  hosts = lib.attrNames inputs.self.hosts;
  remote = pkgs.writeText "fleet-status-remote" ''
    # jobs exist only on agent hosts, the only ones with an agent user
    if u=$(id -u agent 2>/dev/null); then
      # every cgroup with processes, minus the manager itself and its dbus
      find /sys/fs/cgroup/user.slice/user-$u.slice/user@$u.service -name cgroup.procs \
        -not -path '*/init.scope/*' -not -path '*/session.slice/*' | while read -r f; do
        d=''${f%/cgroup.procs}
        pid=$(head -1 "$f" 2>/dev/null) && [ -n "$pid" ] || continue
        read -r t cmd < <(ps -o etime= -o args= -p "$pid") || continue
        printf 'job\t%s\t%s\t%s\n' "''${d##*/}" "$t" "$cmd"
      done
    fi
    # zellij sessions, minus the exited (resurrectable) ones
    zellij list-sessions -n 2>/dev/null | grep -v EXITED | while read -r s _; do
      printf 'zellij\t%s\t%s\n' "$s" "$(zellij -s "$s" action list-clients | tail -n +2 | wc -l)"
    done
    # agents started through the sandbox wrapper, see sandbox.nix; with
    # --unshare-pid, bwrap forks a copy of itself as pid 1 of the new namespace,
    # so only processes in our pid namespace count
    pgrep --ns $$ --nslist pid -u "$UID" -af '^agent-sandbox:' | while read -r pid name _; do
      printf 'session\t%s\t%s\n' "''${name#agent-sandbox:}" "$(readlink "/proc/$pid/cwd")"
    done
  '';
in
pkgs.writeShellApplication {
  name = "fleet-status";
  runtimeInputs = with pkgs; [
    bash
    coreutils
    findutils
    openssh
    procps
  ];
  text = ''
    hosts=("$@")
    [ $# -gt 0 ] || hosts=(${lib.escapeShellArgs hosts})
    rc=0
    for h in "''${hosts[@]}"; do
      run=(ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" bash -s)
      [ "$h" != "$HOSTNAME" ] || run=(bash)
      out=$("''${run[@]}" < ${remote}) || {
        echo "$h: unreachable" >&2
        rc=1
        continue
      }
      [ -z "$out" ] || printf '%s\n' "$out" | sed "s/^/$h\t/"
    done
    exit $rc
  '';
  # for the noctalia widget
  passthru = { inherit hosts; };
}
