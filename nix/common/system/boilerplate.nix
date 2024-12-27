{ user, ... }:
let
  subs = [
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-python.cachix.org"
  ];
in
{
  documentation.man.generateCaches = true; # apropos
  # hardware.enableAllFirmware = true; # regardless of license # TODO figure out if I need this and how to fix it
  hardware.enableRedistributableFirmware = true;
  nix = {
    channel.enable = false;
    nixPath = [ ];
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = subs; # used by default
      trusted-substituters = subs; # merely allowed
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
  nixpkgs.config = {
    allowUnfree = true;
    # cudaSupport = true; # breaks nomacs, mathematica takes a lot of time to compile
    cudnnSupoprt = true;
  };
  time.timeZone = user.timezone;
  i18n.defaultLocale = user.defaultLocale;
  environment.extraOutputsToInstall = [ "info" ];
  users.users.${user.username} = {
    description = user.fullname;
    isNormalUser = true;
    extraGroups = [
      "wheel" # root
      "video" # screen brightness
      "network" # wifi
      "docker" # docker
      "audio" # just in case (?)
      "syncthing" # just in case default syncthing settings are used
      "plugdev" # pluggable devices : required by zsa voyager
      "vboxusers" # virtualbox
      # "input" # le unsecure (?), supposed to be used to get lid state, apparently not required
      "dialout" # serial ports
      "networkmanager"
      "scanner"
      "lp" # printers
      "adbusers" # adb (android)
    ];
  };
}
