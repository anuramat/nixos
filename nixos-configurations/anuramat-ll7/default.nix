{
  config,
  inputs,
  pkgs,
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
    darktable.edid = ./edid.bin;
  };

  imports = [
    inputs.self.nixosModules.base
    inputs.self.nixosModules.laptop

    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    ./nvidia.nix

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

  services = {
    fprintd.enable = true; # goodix 27c6:659a
    tlp = {
      package = pkgs.tlp.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./tlp-performance-on-battery.patch ];
      });
      settings = {
        PLATFORM_PROFILE_ON_BAT = "quiet"; # balanced profile, despite the name
        # RUNTIME_PM_ON_AC=on would keep the dGPU awake on AC: directly, and through
        # its HDMI audio function, a runtime PM consumer of the GPU; the Thunderbolt
        # xHCI needs listing too, since TLP denylists xhci_hcd by default
        RUNTIME_PM_ENABLE = "01:00.0 01:00.1 3d:00.0";
      };
    };
  };

  # fn+q is handled by the firmware and can't be disabled, so undo it; last_pwr
  # is "PROFILE SOURCE", with 0 = performance or AC, 1 = balanced or battery
  systemd.services.fnq-revert = {
    description = "Revert fn+q to the platform profile set by TLP";
    after = [ "tlp.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.inotify-tools ];
    script = ''
      profile=/sys/firmware/acpi/platform_profile
      inotifywait -qm -e modify "$profile" | while read -r _; do
        case "$(cat /run/tlp/last_pwr)" in
          "0 1") want=balanced ;;
          0*) want=performance ;;
          1*) want=quiet ;;
          *) continue ;;
        esac
        if [ "$(cat "$profile")" != "$want" ]; then
          echo "$want" > "$profile" || true
          sleep 1 # the readback lags behind the write
        fi
      done
    '';
  };

  # noctalia's lockscreen talks to fprintd directly; pam_fprintd would make its
  # password auth (PAM service "login") wait for a finger first
  security.pam.services.login.fprintAuth = false;
}
