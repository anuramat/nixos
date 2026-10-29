{
  inputs,
  ...
}:
{
  system.stateVersion = "25.05";
  networking.openconnect.interfaces.uhd.autoStart = true;
  # daily, since it's rarely awake on AC at any given time
  nix.gc.dates = "15:00";

  home-manager.users.${inputs.self.consts.user.username} = {
    services.kanshi.builtinDisplay = {
      criteria = "BOE NV122WUM-N42 Unknown";
      scale = 1.0;
    };
    programs.noctalia.settings.lockscreen_widgets.widget.login.output = "eDP-1";
    screentime.screen = true;
    notifyForward = true;
  };

  # swap partition
  boot.initrd.luks.devices."luks-ffc8e21f-2272-442f-8258-30742e29e1f0".device =
    "/dev/disk/by-uuid/ffc8e21f-2272-442f-8258-30742e29e1f0";

  services.keyd.keyboards.main.ids = [
    "0001:0001:70533846"
    "0001:0001:09b4e68d"
  ];

  imports = [
    inputs.self.nixosModules.base
    inputs.self.nixosModules.laptop
    inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ./hardware-configuration.nix
    ./ancs4linux.nix
    ./tablet.nix
    ./wowlan.nix
  ];

  programs.captive-browser.interface = "wlp0s20f3";
}
