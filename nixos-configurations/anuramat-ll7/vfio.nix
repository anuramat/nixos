{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  user = inputs.self.consts.user.username;
  # RTX 4070 Mobile and its HDMI audio, IOMMU group 13
  gpuIds = "10de:2860,10de:22bd";
  gpu = "0000:01:00.0";
  # for programs that would open the dGPU, through nvidia's vulkan or EGL
  # driver, while rendering on the iGPU
  hideNvidia = {
    VK_LOADER_DRIVERS_DISABLE = "*nvidia*";
    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  };
in
{
  # windows VM with the dGPU passed through; in the default boot entry,
  # libvirt takes the dGPU from the nvidia driver while the VM runs
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
    hooks.qemu = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) {
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
  # gtk4 opens every GPU, see hideNvidia
  systemd.user.services.polkit-soteria.environment = hideNvidia;
  programs.virt-manager.enable = true;
  # the VM is in the system instance; virsh would default to the user's
  environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  users.users.${user}.extraGroups = [
    "libvirtd"
    "kvm"
  ];
  home-manager.users.${user} = {
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
            captureOnFocus = true;
          };
        };
      };
      # niri would keep the nvidia driver in use
      niri.settings.debug.ignore-drm-device = "/dev/dri/by-path/pci-${gpu}-render";
    };
  };

  # separate boot entry with the dGPU bound to vfio-pci from boot, so the
  # nvidia driver never touches it
  specialisation.vfio.configuration = {
    system.nixos.tags = [ "vfio" ];
    environment.etc.specialisation.text = "vfio"; # for `just nixos`

    # the panel stays on the iGPU
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    boot = {
      blacklistedKernelModules = [ "nouveau" ];
      # bind before snd_hda_intel grabs the audio function
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];
      kernelParams = [ "vfio-pci.ids=${gpuIds}" ];
    };
  };
}
