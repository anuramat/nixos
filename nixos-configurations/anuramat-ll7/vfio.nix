{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  user = inputs.self.consts.user.username;
  gpu = "0000:01:00.0"; # RTX 4070 Mobile, with its HDMI audio in IOMMU group 13
  # for programs that would open the dGPU, through nvidia's vulkan or EGL
  # driver, while rendering on the iGPU
  hideNvidia = {
    VK_LOADER_DRIVERS_DISABLE = "*nvidia*";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  };
  hm = config.home-manager.users.${user};
in
{
  # windows VM with the dGPU passed through; libvirt takes the dGPU from the
  # nvidia driver while the VM runs
  imports = [ ./win11 ];

  boot = {
    kernelParams = [ "intel_iommu=on" ]; # don't depend on the kernel's default
    # looking glass shared memory: 3200x2000 SDR frames need ~59MB, rounded up
    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
    kernelModules = [ "kvmfr" ];
    extraModprobeConfig = "options kvmfr static_size_mb=64";
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="${user}", GROUP="kvm", MODE="0660"
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true; # windows 11
      # libvirt's default ACL plus the looking glass device
      verbatimConfig = ''
        namespaces = []
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/userfaultfd", "/dev/kvmfr0"
        ]
      '';
    };
    # unbinding the nvidia driver hangs while anything has the GPU open, so
    # unload it instead, which fails right away; libvirt binds vfio-pci to the
    # freed GPU, and gives it back unbound
    hooks.qemu = {
      win11-gpu = pkgs.writeShellScript "win11-gpu" ''
        PATH=${
          lib.makeBinPath [
            pkgs.kmod
            pkgs.psmisc
            config.systemd.package
          ]
        }
        load() { modprobe -a nvidia_drm nvidia_uvm && systemctl start nvidia-powerd; }
        [ "$1" = win11 ] || exit 0
        case $2 in
          prepare)
            # openrgb opens the dGPU on start; it comes back without it
            systemctl stop nvidia-powerd openrgb
            if ! modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia; then
              fuser -v /dev/nvidia* /dev/dri/by-path/pci-${gpu}-*
              load
              systemctl start openrgb
              exit 1
            fi
            systemctl start openrgb
            ;;
          release) load ;;
        esac
      '';
    };
  };
  # they need the nvidia driver, which is unloaded while the VM runs; skip
  # them instead of failing, e.g. when a switch starts them then
  systemd.services =
    lib.genAttrs [ "nvidia-powerd" "nvidia-container-toolkit-cdi-generator" ] (_: {
      unitConfig.ConditionPathExists = "/sys/module/nvidia";
    })
    // {
      # to switch to the keyd group, which the module's hardening doesn't allow
      keyd.serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];
    };
  # gtk4 opens every GPU, see hideNvidia
  systemd.user.services.polkit-soteria.environment = hideNvidia;
  programs.virt-manager.enable = true;
  # the VM is in the system instance; virsh would default to the user's
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  users.users.${user}.extraGroups = [
    "libvirtd"
    "kvm"
    "keyd" # for keyd-plain-when-inhibited
  ];
  users.groups.keyd = { }; # keyd gives it its socket, see CAP_SETGID
  home-manager.users.${user} = {
    # no keyd remaps while a client inhibits shortcuts, e.g. looking glass
    # while capturing: the guest gets plain keys
    systemd.user.services.keyd-plain-when-inhibited = {
      Unit = {
        After = [ hm.wayland.systemd.target ];
        PartOf = [ hm.wayland.systemd.target ];
      };
      Service = {
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "keyd-plain-when-inhibited";
            runtimeInputs = [
              hm.programs.niri.package
              pkgs.jq
              config.services.keyd.package
            ];
            text = ''
              niri msg -j event-stream |
                jq --unbuffered '.KeyboardShortcutsInhibitChanged | values | .is_inhibiting' |
                while read -r inhibiting; do
                  if [ "$inhibiting" = true ]; then
                    keyd bind reset ${
                      builtins.attrNames config.services.keyd.keyboards.main.settings.main
                      # keyd's defaults: plain keys, and layers for modifiers
                      |> map (
                        k:
                        "${k} = ${
                          {
                            leftalt = "layer(alt)";
                            leftshift = "layer(shift)";
                            rightalt = "layer(altgr)";
                          }
                          .${k} or k
                        }"
                      )
                      |> lib.escapeShellArgs
                    }
                  else
                    keyd bind reset
                  fi
                done
            '';
          }
        );
        Restart = "always"; # the event stream ends when niri restarts
      };
      Install.WantedBy = [ hm.wayland.systemd.target ];
    };
    systemd.user.services.nirimap.Service.Environment = lib.mapAttrsToList (
      k: v: "${k}=${v}"
    ) hideNvidia;
    programs = {
      looking-glass-client = {
        enable = true; # the version must match the guest's host, see ./win11
        settings = {
          win = {
            fullScreen = true;
            showFPS = false;
            noScreensaver = true;
          };
          input = {
            escapeKey = "KEY_INSERT"; # scroll lock needs fn on this keyboard
            rawMouse = true;
          };
        };
      };
      niri.settings = {
        # niri would keep the nvidia driver in use
        debug.ignore-drm-device = "/dev/dri/by-path/pci-${gpu}-render";
        # VRR while looking glass is on screen, so that frames below 165 fps
        # are shown when they arrive, not at the next fixed refresh
        outputs."eDP-1".variable-refresh-rate = "on-demand";
        window-rules = [
          {
            matches = [ { app-id = "^looking-glass-client$"; } ];
            variable-refresh-rate = true;
          }
        ];
      };
    };
  };
}
