# relays: channels from the agent sandboxes to the host, each a unix socket
# `$XDG_RUNTIME_DIR/NAME.sock`, bound into every sandbox; a client (client.py)
# sends a command line, and the host side (receiver.py, one per connection)
# logs it, runs the relay's handler on the caller's stdio, and passes its exit
# status back; the log: `journalctl --user -u 'NAME@*'`
{
  config,
  lib,
  pkgs,
  ...
}:
let
  receiver = pkgs.writers.writePython3Bin "relay-receiver" { } (builtins.readFile ./receiver.py);
in
{
  options.agents.relays = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    description = ''
      relay name -> handler command line; the handler gets the caller's
      command as an extra last argument, the caller's stdin, stdout and
      stderr, and RELAY_CALLER (the sandbox, see sandbox.nix) and RELAY_CWD
      (the caller's cwd, which may not exist outside the sandbox) in the
      environment; once the caller hangs up, it gets SIGTERM
    '';
  };

  config = {
    # `relay-client NAME SECONDS CMD...`, for the relays' own commands
    lib.agents.relayClient = pkgs.writers.writePython3Bin "relay-client" { } (
      builtins.readFile ./client.py
    );

    systemd.user = {
      sockets = lib.mapAttrs (name: _: {
        Socket = {
          ListenStream = "%t/${name}.sock";
          SocketMode = "0600";
          Accept = true;
        };
        Install.WantedBy = [ "sockets.target" ];
      }) config.agents.relays;
      services = lib.mapAttrs' (
        name: handler:
        lib.nameValuePair "${name}@" {
          Unit.CollectMode = "inactive-or-failed";
          Service = {
            ExecStart = "${lib.getExe receiver} ${handler}";
            StandardInput = "socket";
            # both would default to the socket
            StandardOutput = "journal";
            StandardError = "journal";
          };
        }
      ) config.agents.relays;
    };
  };
}
