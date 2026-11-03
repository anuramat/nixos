{
  config,
  inputs,
  ...
}:
{
  system.stateVersion = "26.05";
  programs.captive-browser.interface = "wlp0s20f3";
  services.keyd.keyboards.main.ids = [
    "048d:c997:da10980f"
  ];

  home-manager.users.${inputs.self.consts.user.username} = {
    services.kanshi.builtinDisplay = {
      criteria = "California Institute of Technology 0x1626 0x00006002";
      scale = 1.5;
    };
    programs.noctalia.settings.lockscreen_widgets.widget.login.output = "eDP-1";
  };

  imports = [
    inputs.self.nixosModules.base
    inputs.self.nixosModules.laptop

    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    ./nvidia-host.nix

    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

    ./hardware-configuration.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.lenovo-legion-module
  ];

  hardware.graphics.enable32Bit = true; # compat
}
