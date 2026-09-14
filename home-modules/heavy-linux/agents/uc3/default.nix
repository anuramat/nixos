{
  pkgs,
  config,
  ...
}:
let
  excludeShellChecks = map (v: "SC" + toString v) config.lib.shellcheck.excludes;

  uc3Client = pkgs.writers.writePython3Bin "uc3-client" { } (builtins.readFile ./uc3-client.py);

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
in
{
  home.packages = [ uc3ctl ];

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
    services."uc3-broker@" = {
      Unit.CollectMode = "inactive-or-failed";
      Service = {
        ExecStart = "${broker}/bin/uc3-broker";
        StandardInput = "socket";
        StandardOutput = "socket";
        StandardError = "journal";
        StateDirectory = "uc3";
      };
    };
    services.uc3-master = {
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
  };
}
