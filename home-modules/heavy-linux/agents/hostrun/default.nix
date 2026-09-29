# lets sandboxed agents ask to run a command outside the sandbox: the request
# pops up as a notification on the prompt host, whose [Review] opens a terminal
# with the full request; once approved there, the command runs as the user on
# the agent's host, in the agent's cwd, straight on the agent's stdout and
# stderr, and its exit status is passed back; requests and outcomes are logged
# on the agent's host: `journalctl --user -u 'hostrun@*'`
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # PoC: every host asks on f12
  promptHost = "anuramat-f12";
  appId = "sn.ctrl.hostrun";

  client = pkgs.writers.writePython3Bin "hostrun" { } (builtins.readFile ./client.py);
  broker = pkgs.writers.writePython3Bin "hostrun-broker" { flakeIgnore = [ "E501" ]; } (
    builtins.readFile ./broker.py
  );

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

  # reads the request on stdin, prints allow or deny
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
      cat >"$dir/request"
      # ssh sessions don't get the address, but the session bus is still there
      export DBUS_SESSION_BUS_ADDRESS=''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
      action=$(notify-send --wait --urgency=critical --expire-time=0 --app-name=hostrun \
        --action=review=Review --action=deny=Deny \
        "hostrun: $(head -1 "$dir/request")" "$(tail -n +2 "$dir/request")")
      if [ "$action" = review ]; then
        # systemd-run: the graphical session's environment, which ssh sessions
        # lack; a separate instance, so that --wait waits for this very window
        systemd-run --user --wait --collect --quiet -- \
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

  systemd.user = {
    sockets.hostrun = {
      Socket = {
        ListenStream = "%t/hostrun.sock";
        SocketMode = "0600";
        Accept = true;
      };
      Install.WantedBy = [ "sockets.target" ];
    };
    services."hostrun@" = {
      Unit.CollectMode = "inactive-or-failed";
      Service = {
        ExecStart = "${lib.getExe broker} ${promptHost} ${lib.getExe prompt}";
        Environment = "BASH_ENV=${bashEnv}";
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };

  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^${lib.escapeRegex appId}$"; } ];
      open-floating = true;
    }
  ];
}
