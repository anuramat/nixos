# let agents run stuff over ssh, with logs under `journalctl -t agent-ssh`
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  username = config.lib.hosts.agentUsername;
  shell = pkgs.writeShellApplication {
    name = "agent-shell";
    runtimeInputs = with pkgs; [
      bashInteractive
      util-linux # logger
    ];
    text = ''
      cmd=''${SSH_ORIGINAL_COMMAND-}
      logger -t agent-ssh -- "''${SSH_CLIENT%% *} ''${cmd:-<interactive>}"
      [ -n "$cmd" ] || exec bash
      exec bash -c "$cmd"
    '';
  };
in
{
  config = lib.mkIf inputs.self.hosts.${config.networking.hostName}.agent {
    users = {
      users.${inputs.self.user.username}.extraGroups = [ username ]; # browse /home/${username} without sudo
      users.${username} = {
        isNormalUser = true;
        group = username;
        homeMode = "0750";
        linger = true; # so `systemd-run --user` jobs outlive the ssh session
        packages = config.home-manager.users.${inputs.self.user.username}.home.packages;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEDuJzoF9hhYfPWeV8wA0QEiFzvtdtqLwFa6gRCh5Vt" # secrets/agent.age
        ];
      };
      groups.${username} = { };
    };
    services.openssh = {
      settings.AllowUsers = [ username ];
      extraConfig = ''
        Match User ${username}
          ForceCommand ${lib.getExe shell}
          DisableForwarding yes
      '';
    };
  };
}
