{
  pkgs,
  config,
  ...
}:
let
  excludeShellChecks = map (v: "SC" + toString v) config.lib.shellcheck.excludes;

  broker = pkgs.writeShellApplication {
    name = "uc3-broker";
    inherit excludeShellChecks;
    text = builtins.readFile ./broker.sh;
  };

  uc3ctl = pkgs.writeShellApplication {
    name = "uc3ctl";
    runtimeInputs = [ pkgs.socat ];
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
  };
}
