# a relay (see ../relay) that lets sandboxed agents ask to run a command
# outside the sandbox: the request pops up as a notification on every
# physical machine, whose [Review] opens a terminal with the full request;
# hosts that can't show one yet (asleep, offline) get retried; the first
# answer counts and withdraws the other prompts; once approved, the command
# runs as the user on the agent's host, in the agent's cwd, straight on the
# agent's stdout and stderr, and its exit status is passed back; an agent
# that hangs up withdraws the prompts, or stops the command; requests and
# outcomes are logged on the agent's host: `journalctl --user -u 'hostrun@*'`
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  promptHosts =
    inputs.self.hosts |> lib.filterAttrs (_: h: h.local && !h.deprecated) |> lib.attrNames;
  appId = "sn.ctrl.hostrun";

  client = pkgs.writeShellApplication {
    name = "hostrun";
    runtimeInputs = [ config.lib.agents.relayClient ];
    text = ''exec relay-client hostrun 0 "$@"'';
  };
  handler = pkgs.writers.writePython3Bin "hostrun-handler" {
    libraries = [ pkgs.python3Packages.systemd-python ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./handler.py);

  review = pkgs.writeShellApplication {
    name = "hostrun-review";
    text = ''
      # control characters are shown instead of interpreted, so that the
      # command can't hide parts of itself
      cat -v "$1/request"
      echo
      read -rp 'run it? [y/N] ' answer
      [ "$answer" != y ] || touch "$1/allow"
    '';
  };

  # reads the request on stdin, prints allow or deny; withdraws the prompt
  # once stdin ends or goes quiet
  prompt = pkgs.writeShellApplication {
    name = "hostrun-prompt";
    runtimeInputs = with pkgs; [
      coreutils
      # upstream notify-send --wait hangs when it can't show the notification,
      # e.g. without a desktop session
      (libnotify.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./notify-send-wait.patch ];
      }))
      systemd
    ];
    text = ''
      dir=$(mktemp -d)
      trap 'rm -rf "$dir"' EXIT
      # the request ends with a NUL; stdin then stays open until any host has an
      # answer, or the requester is gone
      IFS= read -r -d "" request
      printf '%s' "$request" >"$dir/request"
      unit=hostrun-review-''${dir##*.}
      # ssh sessions don't get the address, but the session bus is still there
      export DBUS_SESSION_BUS_ADDRESS=''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
      body=$(tail -n +2 "$dir/request")
      # notify-send expands backslash escapes in the body
      notify-send --wait --urgency=critical --expire-time=0 --app-name=hostrun \
        --action=review=Review --action=deny=Deny \
        "hostrun: $(head -1 "$dir/request")" "''${body//\\/\\\\}" >"$dir/action" &
      notify=$!
      # withdraw once the broker hangs up or misses 3 heartbeats (one every 30s);
      # notify-send closes its notification on SIGINT; the explicit stdin, since
      # background jobs get /dev/null otherwise
      {
        set +e
        while read -r -t 90; do :; done
        kill -INT "$notify"
        systemctl --user stop "$unit"
      } <&0 >/dev/null 2>&1 &
      watcher=$!
      # needed only while this runs, and mustn't signal a stale pid later
      trap 'rm -rf "$dir"; kill "$watcher" 2>/dev/null' EXIT
      wait "$notify"
      if [ "$(<"$dir/action")" = review ]; then
        # systemd-run: the graphical session's environment, which ssh sessions
        # lack; a separate instance, so that --wait waits for this very window
        systemd-run --user --wait --collect --quiet --unit="$unit" -- \
          ${lib.getExe config.programs.ghostty.package} --class=${appId} \
          --gtk-single-instance=false --title=hostrun -e ${lib.getExe review} "$dir"
      fi
      if [ -e "$dir/allow" ]; then echo allow; else echo deny; fi
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
  ];

  agents.relays.hostrun = "${lib.getExe handler} ${lib.getExe prompt} ${toString promptHosts}";
  systemd.user.services."hostrun@".Service.Environment = "BASH_ENV=${bashEnv}";

  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^${lib.escapeRegex appId}$"; } ];
      open-floating = true;
    }
  ];
}
