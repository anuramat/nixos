{
  unstable,
  dummy,
  cluster,
  ...
}:
{
  documentation.man.generateCaches = true; # apropos
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

  # realtime kit, hands out realtime priority to user processes
  security.rtkit.enable = true;

  virtualisation = {
    virtualbox.host = {
      enable = true;
      # enableExtensionPack = true; # allegedly causes frequent recompilation: <https://nixos.wiki/wiki/VirtualBox>
    };
    # common container config files in /etc/containers
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs = {
    # gnome keyring frontend
    seahorse.enable = true;
    # adb
    adb.enable = true;
    # udisks2 frontend
    gnome-disks.enable = true;
  };

  services = {
    # removable media stuff
    udisks2 = {
      enable = true;
      mountOnMedia = true;
    };
    # security credential storage, exposed over dbus
    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
