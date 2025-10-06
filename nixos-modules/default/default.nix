# vim: fdl=0 fdm=marker
{
  config,
  hax,
  inputs,
  ...
}:
{
  imports = [
    ./external_keys.nix
    ./home.nix
    ./hosts.nix
    ./net.nix
    ./nix.nix
    ./user.nix
    ../user-config.nix

    inputs.agenix.nixosModules.default
    inputs.self.sharedModules.age
    inputs.nix-topology.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager =
    let
      username = config.userConfig.username;
    in
    {
      extraSpecialArgs = {
        inherit hax inputs;
      };
      users.${username} = {
        imports = with inputs.self.homeModules; [
          default
          linux
        ];
      };
    };

  # TODO move stuff that is not required on a server

  security = {
    rtkit.enable = true; # realtime kit, hands out realtime priority to user processes
    # TODO doesn't work
    # need to expose GNUPGHOME for starters
    pam.services.login.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = true;
    };
    pam.services.swaylock.gnupg = {
      enable = true;
      noAutostart = true;
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";

  security.soteria.enable = true; # polkit auth agent

  boot.initrd.systemd.enable = true; # TODO idk why I have this

  # TODO check through virtualisation; also maybe we can move some of it
  virtualisation = {
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
  hardware.nvidia-container-toolkit = {
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true; # TODO ?
  };

  services.getty.autologinOnce = true; # autologin on boot on the first tty (it's encrypted anyway)
  hardware.enableAllFirmware = true; # as in "regardless of license"
  programs.iotop = {
    # setcap wrapper to use rootless
    enable = true;
  };

  # environment.systemPackages = with pkgs; [
  #   hyprpolkitagent
  # ];
}
