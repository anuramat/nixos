{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.lib.shellcheck) excludeShellChecks;

  mkScript =
    name: file: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs excludeShellChecks;
      text = builtins.readFile file;
    };

  handler = mkScript "uc3-handler" ./handler.sh (
    with pkgs;
    [
      coreutils
      gnugrep
      openssh
      systemd
    ]
  );
  uc3ctl = mkScript "uc3ctl" ./shim.sh [
    pkgs.coreutils
    config.lib.agents.relayClient
  ];
  uc3pull = mkScript "uc3pull" ./uc3pull.sh (
    with pkgs;
    [
      coreutils
      croc
      diffutils
      findutils
      uc3ctl
    ]
  );
  status = mkScript "uc3-status" ./status.sh [
    pkgs.coreutils
    uc3ctl
  ];
in
{
  # for the noctalia fleet monitor plugin, which follows uc3-status.service's
  # snapshot there
  lib.uc3.stateDir = "${config.xdg.stateHome}/uc3";

  home.packages = [
    uc3ctl
    uc3pull
  ];

  agents.relays.uc3 = lib.getExe handler;

  systemd.user = {
    sockets.uc3.Socket.MaxConnections = 8;
    services = {
      "uc3@".Service.StateDirectory = "uc3";
      uc3-master = {
        Unit.Description = "shared ssh master for uc3";
        Service = {
          # ssh -f returns once logged in, so `systemctl start` blocks on the login
          Type = "forking";
          Environment = [
            "SSH_ASKPASS=${config.home.profileDirectory}/bin/uc3-askpass"
            "SSH_ASKPASS_REQUIRE=force"
          ];
          ExecStart = "${lib.getExe pkgs.openssh} -o ConnectTimeout=15 -fN uc3";
          # the broker reads this to tell a refused login from an unreachable cluster
          StandardError = "truncate:%S/uc3/login.err";
          StateDirectory = "uc3";
        };
      };
      uc3-status = {
        Unit.Description = "uc3 partition and job snapshot";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe status;
          # the fleet monitor shows its last line; empty after a successful fetch
          StandardError = "truncate:%S/uc3/status.err";
          StateDirectory = "uc3";
        };
      };
    };
    # hourly, so a flaky login can't hammer the cluster
    timers.uc3-status = {
      Timer = {
        OnCalendar = "hourly";
        # fetch on boot if the machine was off at the last full hour
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
