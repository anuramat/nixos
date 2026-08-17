{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # unattended wayland access: root service injects input via uinput,
  # screen capture goes through the user session's screencast portal
  boot.kernelModules = [ "uinput" ];

  systemd.services.rustdesk = {
    description = "RustDesk";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    # logind reports the getty-autologin session as "tty"; rustdesk then falls
    # back to this variable, and without it assumes x11
    environment.XDG_SESSION_TYPE = "wayland";
    # rustdesk shells out: sudo spawns the user-session --server (which is what
    # registers the ID), plus ps/which/sh for session discovery
    path = [
      "/run/wrappers"
      pkgs.procps
      pkgs.which
      pkgs.bash
    ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.rustdesk-flutter} --service";
      # kill --server and --tray subprocesses too (upstream unit does the same)
      ExecStop = "-${lib.getExe' pkgs.procps "pkill"} -f 'rustdesk --'";
      KillMode = "mixed";
      User = "root"; # makes systemd set HOME, where rustdesk keeps its config
    };
  };

  # direct IP access over the tailnet, bypassing the public rendezvous/relay
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 21118 ];

  home-manager.users.${inputs.self.user.username} = {
    # rustdesk can't answer the interactive output chooser; share the first
    # output without prompting (affects all screencasts on this host)
    xdg.configFile."xdg-desktop-portal-wlr/config".text = ''
      [screencast]
      chooser_type = none
    '';
  };
}
