# a relay (see ../relay) that lets sandboxed agents ask to run a command
# outside the sandbox: the request's description pops up as a notification
# on every physical machine, whose [Review] opens a terminal with the full
# request; `hostrun-review` answers the host's pending requests from any
# terminal instead, e.g. over ssh;
# hosts that can't show one yet (asleep, offline) get retried; the first
# answer counts and withdraws the other prompts; once approved, the command
# runs as the user on the agent's host, in the agent's cwd, or with -h, over
# ssh on another host, in the user's home there, straight on the agent's
# stdout and stderr, and its exit status is passed back; an agent
# that hangs up withdraws the prompts, or stops the command; requests and
# outcomes are logged on the agent's host: `journalctl --user -u 'hostrun@*'`;
# the review also shows the decision model's verdicts on whether the command
# can destroy data in $HOME or on other disks (questions.json, evaluated by
# eval/eval.py)
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  promptHosts = inputs.self.hosts |> lib.filterAttrs (_: h: h.local) |> lib.attrNames;
  appId = "sn.ctrl.hostrun";
  inherit (inputs.self.consts.llama) host decisionPort;

  client = pkgs.writeShellApplication {
    name = "hostrun";
    runtimeInputs = [ config.lib.agents.relayClient ];
    # -f sends FILE's content, read here, so that the prompt shows all of it,
    # and the host runs what was approved, even if FILE changes or exists only
    # in the sandbox
    text = ''
      usage() {
        echo 'usage: hostrun -d DESCRIPTION [-h HOST] {-c CMD | -f FILE}' >&2
        exit 2
      }
      desc="" host="" cmd="" # host: this one
      while getopts d:h:c:f: opt; do
        case $opt in
          d) desc=$OPTARG ;;
          h) host=$OPTARG ;;
          c) cmd=$OPTARG ;;
          f) cmd=$(<"$OPTARG") ;;
          *) usage ;;
        esac
      done
      if [ -z "$desc" ] || [ -z "$cmd" ] || [ "$OPTIND" -le "$#" ]; then usage; fi
      exec relay-client hostrun 0 "$desc" "$host" "$cmd"
    '';
  };
  handler = pkgs.writers.writePython3Bin "hostrun-handler" {
    libraries = [ pkgs.python3Packages.systemd-python ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./handler.py);

  # answers the given request, or, from a terminal, every pending one
  review = pkgs.writeShellApplication {
    name = "hostrun-review";
    text = ''
      shopt -s nullglob
      [ "$#" -gt 0 ] || set -- "$XDG_RUNTIME_DIR"/hostrun/*
      [ "$#" -gt 0 ] || echo 'nothing pending'
      for dir; do
        # control characters are shown instead of interpreted, so that the
        # command can't hide parts of itself
        cat -v "$dir/request"
        echo
        read -rp 'run it? [y/N] ' answer
        if [ "$answer" = y ]; then answer=allow; else answer=deny; fi
        # read-write, so that a fifo left without its prompt can't block this
        { echo "$answer" 1<>"$dir/answer"; } 2>/dev/null || echo 'already withdrawn'
      done
    '';
  };

  # reads the description and the request on stdin, prints allow or deny;
  # withdraws the prompt once stdin ends or goes quiet; the request stays open
  # to hostrun-review, even while the notification can't be shown
  prompt = pkgs.writeShellApplication {
    name = "hostrun-prompt";
    runtimeInputs = with pkgs; [
      coreutils
      procps # pkill
      # upstream notify-send --wait hangs when it can't show the notification,
      # e.g. without a desktop session
      (libnotify.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./notify-send-wait.patch ];
      }))
      systemd
    ];
    text = ''
      # where hostrun-review finds it, and the sandboxes can't
      mkdir -p "$XDG_RUNTIME_DIR/hostrun"
      dir=$(mktemp -d -p "$XDG_RUNTIME_DIR/hostrun")
      trap 'rm -rf "$dir"' EXIT
      trap exit HUP PIPE TERM # so that the EXIT trap runs
      # the description and the request each end with a NUL; stdin then stays
      # open until any host has an answer, or the requester is gone
      IFS= read -r -d "" desc
      IFS= read -r -d "" request
      printf '%s' "$request" >"$dir/request"
      unit=hostrun-review-''${dir##*.}
      # ssh sessions don't get the address, but the session bus is still there
      export DBUS_SESSION_BUS_ADDRESS=''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
      # the first line written here is the answer; read-write, so that opening
      # it doesn't wait for a writer
      mkfifo "$dir/answer"
      exec 3<>"$dir/answer"
      (
        # just the description: the whole request can push the buttons out of a
        # long notification; notify-send expands backslash escapes in the body;
        # it fails without a desktop session, which may still appear
        until notify-send --wait --urgency=critical --expire-time=0 --app-name=hostrun \
          --action=review=Review --action=deny=Deny \
          "hostrun: $(head -1 "$dir/request")" "''${desc//\\/\\\\}" >"$dir/action"; do
          # outlives this subshell, and ssh would wait for it on the outputs
          sleep 30 >/dev/null 2>&1
        done
        if [ "$(<"$dir/action")" = review ]; then
          # systemd-run: the graphical session's environment, which ssh sessions
          # lack; a separate instance, so that --wait waits for this very window
          systemd-run --user --wait --collect --quiet --unit="$unit" -- \
            ${lib.getExe config.programs.ghostty.package} --class=${appId} \
            --gtk-single-instance=false --title=hostrun -e ${lib.getExe review} "$dir" || true
        fi
        echo deny >&3
      ) &
      offer=$!
      # withdraw once the broker hangs up or misses 3 heartbeats (one every 30s);
      # the explicit stdin, since background jobs get /dev/null otherwise
      {
        while read -r -t 90; do :; done
        echo deny >&3
      } <&0 >/dev/null 2>&1 &
      watcher=$!
      # notify-send closes its notification on SIGINT
      cleanup() {
        set +e
        pkill -INT -P "$offer"
        kill "$offer" "$watcher"
        systemctl --user stop "$unit"
        rm -rf "$dir"
      } >/dev/null 2>&1
      trap cleanup EXIT
      IFS= read -r answer <&3
      echo "$answer"
    '';
  };

  # the user's session variables for the approved command's bash, minus the
  # ones the sandbox drops too
  bashEnv = pkgs.writeText "hostrun-env" ''
    . ${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
    unset BASH_ENV GIT_EXTERNAL_DIFF
  '';
in
{
  home.packages = [
    client
    prompt # found in PATH over ssh
    review
  ];

  agents.relays.hostrun = lib.concatStringsSep " " [
    (lib.getExe handler)
    (lib.getExe prompt)
    (lib.concatStringsSep "," promptHosts)
    "http://${host}:${toString decisionPort}/v1/systemone"
    "${./questions.json}"
  ];
  systemd.user.services."hostrun@".Service.Environment = "BASH_ENV=${bashEnv}";

  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^${lib.escapeRegex appId}$"; } ];
      open-floating = true;
    }
  ];
}
