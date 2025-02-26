{
  unstable,
  dummy,
  cluster,
  ...
}:
{
  imports = dummy ./.;
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.ssh.knownHostsFiles = cluster.hostKeysFiles;

  programs.adb.enable = true; # android stuff
  security.rtkit.enable = true; # realtime kit, hands out realtime priority to user processes

  fonts = {
    packages = with unstable; [
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];
      };
    };
  };

  virtualisation = {
    virtualbox = {
      host = {
        enable = true;
      };
      guest = {
        enable = true;
      };
    };
    # common container config files in /etc/containers
    containers.enable = true;
    podman = {
      enable = true;
      # docker aliases
      dockerCompat = true;
      # > Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
