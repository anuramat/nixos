{
  pkgs,
  config,
  ...
}:
let
  excludeShellChecks = map (v: "SC" + toString v) config.lib.shellcheck.excludes;

  uc3Client = pkgs.writers.writePython3Bin "uc3-client" { } (builtins.readFile ./uc3-client.py);
  uc3Recv = pkgs.writers.writePython3Bin "uc3-recv" { } (builtins.readFile ./recv.py);

  broker = pkgs.writeShellApplication {
    name = "uc3-broker";
    runtimeInputs = with pkgs; [
      coreutils
      openssh
      systemd
      util-linux
    ];
    inherit excludeShellChecks;
    text = builtins.readFile ./broker.sh;
  };

  uc3ctl = pkgs.writeShellApplication {
    name = "uc3ctl";
    runtimeInputs = with pkgs; [
      coreutils
      uc3Client
    ];
    inherit excludeShellChecks;
    text = builtins.readFile ./shim.sh;
  };

  uc3pull = pkgs.writeShellApplication {
    name = "uc3pull";
    runtimeInputs = with pkgs; [
      coreutils
      croc
      diffutils
      findutils
      uc3ctl
    ];
    inherit excludeShellChecks;
    text = builtins.readFile ./uc3pull.sh;
  };

  status = pkgs.writeShellApplication {
    name = "uc3-status";
    runtimeInputs = with pkgs; [
      coreutils
      uc3ctl
    ];
    inherit excludeShellChecks;
    text = builtins.readFile ./status.sh;
  };
in
{
  # for the noctalia fleet monitor plugin, which follows uc3-status.service's
  # snapshot there
  lib.uc3.stateDir = "${config.xdg.stateHome}/uc3";

  home.packages = [
    uc3ctl
    uc3pull
  ];

  systemd.user = {
    sockets.uc3-broker = {
      Socket = {
        ListenStream = "%t/uc3.sock";
        SocketMode = "0600";
        Accept = true;
        MaxConnections = 8;
      };
      Install.WantedBy = [ "sockets.target" ];
    };
    services = {
      "uc3-broker@" = {
        Unit.CollectMode = "inactive-or-failed";
        Service = {
          ExecStart = "${uc3Recv}/bin/uc3-recv ${broker}/bin/uc3-broker";
          StandardInput = "socket";
          StandardOutput = "socket";
          StandardError = "journal";
          StateDirectory = "uc3";
        };
      };
      uc3-master = {
        Unit.Description = "shared ssh master for uc3";
        Service = {
          # ssh -f returns once logged in, so `systemctl start` blocks on the login
          Type = "forking";
          Environment = [
            "SSH_ASKPASS=${config.home.profileDirectory}/bin/uc3-askpass"
            "SSH_ASKPASS_REQUIRE=force"
          ];
          ExecStart = "${pkgs.openssh}/bin/ssh -o ConnectTimeout=15 -fN uc3";
          # the broker reads this to tell a refused login from an unreachable cluster
          StandardError = "truncate:%S/uc3/login.err";
          StateDirectory = "uc3";
        };
      };
      uc3-status = {
        Unit.Description = "uc3 partition and job snapshot";
        Service = {
          Type = "oneshot";
          ExecStart = "${status}/bin/uc3-status";
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
