# long-running jobs, run as the agent user under `systemd-run --user`, so they
# outlive sandboxed sessions and show up in fleet-status; every command runs on
# the job's host over ssh, even when it's this one; the job's dir
# /home/agent/shared/jobs/NAME on HOST is staged by the caller (e.g. `rsync ...
# HOST:DIR`), then used as the working dir and for `log` and `result`
{ pkgs, inputs, ... }:
let
  inherit (inputs.self.accounts.agent) username sharedDir;
  # the ExecStopPost; a script, since systemd saves a transient unit with every
  # `$` doubled, so an inline `$$` comes back as `$$$$` after a reload (e.g. a
  # rebuild), and the job's result as the shell's PID
  writeResult = pkgs.writeShellScript "job-result" ''
    echo "$SERVICE_RESULT $EXIT_CODE $EXIT_STATUS" >result.tmp && mv result.tmp result
  '';
  job = pkgs.writeShellApplication {
    name = "job";
    runtimeInputs = with pkgs; [
      coreutils
      openssh
    ];
    text = ''
      usage="usage: job run HOST:NAME -- CMD... | job wait [-f] HOST:NAME | job stop HOST:NAME"
      die() {
        echo "job: $*" >&2
        exit 1
      }

      (($#)) || die "$usage"
      sub=$1
      shift
      opts=()
      if [[ $sub == wait && ''${1-} == -f ]]; then
        opts=(-f)
        shift
      fi

      # everything runs as the agent user on the job's host; get there first,
      # passing just NAME
      if [[ $(id -un) != ${username} ]]; then
        [[ ''${1-} == *:* ]] || die "$usage"
        # shellcheck disable=SC2029 # expanded locally on purpose, then %q-quoted
        ssh "''${1%%:*}" "$(printf '%q ' job "$sub" "''${opts[@]}" "''${1#*:}" "''${@:2}")" || {
          rc=$?
          ((rc != 255)) || rc=4 # ssh itself failed
          exit "$rc"
        }
        exit
      fi

      (($#)) || die "$usage"
      name=$1
      shift
      [[ $name =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "bad name: $name"
      D=${sharedDir}/jobs/$name
      unit=job-$name

      case $sub in
      run)
        [[ ''${1-} == -- ]] || die "$usage"
        shift
        (($#)) || die "$usage"
        [ -d "$D" ] || die "stage the job in $D first"
        [ ! -e "$D/result" ] || die "$D/result exists, the job already ran"
        # without --expand-environment=no, systemd would expand $VARs in CMD;
        # append, since ExecStopPost reopens the log
        exec systemd-run --user --unit="$unit" --collect --expand-environment=no \
          --working-directory="$D" -p StandardOutput="append:$D/log" \
          -p ExecStopPost=${writeResult} \
          "$@"
        ;;
      stop)
        exec systemctl --user stop "$unit"
        ;;
      wait)
        if [ ! -e "$D/log" ]; then
          echo "job $name: no such job"
          exit 2
        fi
        cgroup=/sys/fs/cgroup/user.slice/user-$UID.slice/user@$UID.service/app.slice/$unit.service
        # the result is written before the cgroup goes away, so a job that
        # vanished without one is lost (e.g. reboot)
        poll() {
          until [ -e "$D/result" ]; do
            [ -d "$cgroup" ] || [ -e "$D/result" ] || return 3
            sleep 5
          done
        }
        rc=0
        if ((''${#opts[@]})); then
          poll &
          pid=$!
          # new lines only; exits after poll does, once the rest is printed
          tail -n 0 -F --pid="$pid" "$D/log" 2>/dev/null || true
          wait "$pid" || rc=$?
        else
          poll || rc=$?
        fi
        if ((rc)); then
          echo "job $name: lost"
          exit 3
        fi
        read -r result <"$D/result"
        echo "job $name: $result"
        # a cancelled job is "success killed TERM"
        [[ $result == "success exited 0" ]]
        ;;
      *)
        die "$usage"
        ;;
      esac
    '';
  };
in
{
  home.packages = [ job ];
}
