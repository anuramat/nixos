{
  unstable,
  dummy,
  cluster,
  ...
}:
{
  hardware.enableAllFirmware = true; # regardless of license
  environment.extraOutputsToInstall = [ "info" ];
  programs.ssh.knownHostsFiles = cluster.hostKeysFiles;
  imports = dummy ./.;

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

  programs.adb.enable = true; # android stuff

  # realtime kit, hands out realtime priority to user processes
  security.rtkit.enable = true;

  services = {
    # removable media stuff
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
