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
  sharedDir = "${config.users.users.${username}.home}/shared";
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
        extraGroups = [ "systemd-journal" ];
        homeMode = "0750";
        linger = true; # so `systemd-run --user` jobs outlive the ssh session
        packages = config.home-manager.users.${inputs.self.user.username}.home.packages;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEDuJzoF9hhYfPWeV8wA0QEiFzvtdtqLwFa6gRCh5Vt" # secrets/agent.age
        ];
      };
      groups.${username} = { };
    };
    # anything the agent leaves behind in an ssh session dies with it, so only
    # `systemd-run --user` jobs outlive a connection
    services.logind.settings.Login = {
      KillUserProcesses = true;
      KillOnlyUsers = username;
    };
    # dir the user's sandboxed agents can read but only write through ssh (e.g.
    # `rsync ... HOST:DIR`), so everything in it is owned by the agent user
    systemd.tmpfiles.rules = [ "d ${sharedDir} 0750 ${username} ${username} -" ];
    home-manager.users.${inputs.self.user.username}.agents.sandbox.roDirs = [ sharedDir ];
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
