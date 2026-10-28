# list the units running under the agent user's systemd (`systemd-run --user`
# jobs, scopes, custom slices; agent hosts only), the current user's sandboxed
# agent sessions and live zellij sessions on the given host, as
# `job<TAB>UNIT<TAB>ELAPSED<TAB>ETA<TAB>DESC` (ETA and DESC are set by
# `job run`, see agents/job.nix; empty for other units and jobs without them),
# `session<TAB>WRAPPER<TAB>CWD`, `zellij<TAB>SESSION<TAB>CLIENTS`, plus the
# bgm5powerctl profile (bgm5 only) as `power<TAB>MODE` and the battery charge
# (laptops only) as `battery<TAB>PERCENT`; units are read from the
# world-readable cgroupfs, so it needs neither the agent's user bus nor its ssh
# key; the current host is queried directly instead of over ssh
{
  pkgs,
  lib,
  inputs,
}:
let
  hosts = lib.attrNames inputs.self.hosts;
  remote = pkgs.writeText "fleet-probe-remote" ''
    # jobs exist only on agent hosts, the only ones with an agent user
    if u=$(id -u ${inputs.self.consts.agent.username} 2>/dev/null); then
      # every cgroup with processes, minus the manager itself and its dbus
      find /sys/fs/cgroup/user.slice/user-$u.slice/user@$u.service -name cgroup.procs \
        -not -path '*/init.scope/*' -not -path '*/session.slice/*' | while read -r f; do
        d=''${f%/cgroup.procs}
        pid=$(head -1 "$f" 2>/dev/null) && [ -n "$pid" ] || continue
        read -r t < <(ps -o etime= -p "$pid") || continue
        unit=''${d##*/} eta="" desc=""
        if [[ $unit =~ ^job-(.*)\.service$ ]]; then
          j=${inputs.self.consts.agent.sharedDir}/jobs/''${BASH_REMATCH[1]}
          eta=$(head -1 "$j/eta" 2>/dev/null) desc=$(head -1 "$j/desc" 2>/dev/null)
        fi
        printf 'job\t%s\t%s\t%s\t%s\n' "$unit" "$t" "$eta" "$desc"
      done
    fi
    # fan/tctl profile, see bgm5's power.nix
    ! command -v bgm5powerctl >/dev/null || printf 'power\t%s\n' "$(bgm5powerctl status)"
    # the system battery; peripherals' batteries are named after their device
    for b in /sys/class/power_supply/BAT*/capacity; do
      [ ! -e "$b" ] || printf 'battery\t%s\n' "$(<"$b")"
    done
    # zellij sessions, minus the exited (resurrectable) ones; a hung session
    # would block the script, and over ssh nothing kills it once the poll gives up
    timeout 5 zellij list-sessions -n 2>/dev/null | grep -v EXITED | while read -r s _; do
      printf 'zellij\t%s\t%s\n' "$s" "$(timeout 5 zellij -s "$s" action list-clients | tail -n +2 | wc -l)"
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
  name = "fleet-probe";
  runtimeInputs = with pkgs; [
    bash
    coreutils
    findutils
    gnugrep
    openssh
    procps
  ];
  text = ''
    [ "$1" != "$HOSTNAME" ] || exec bash <${remote}
    exec ssh -o BatchMode=yes -o ConnectTimeout=5 "$1" bash -s <${remote}
  '';
  passthru = { inherit hosts; };
}
