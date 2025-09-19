{ config, pkgs, ... }:
# WARN doesn't work yet
{
  # Bind the 4070 + its audio to vfio early
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  # Keep host NVIDIA drivers from grabbing the GPU
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  # Enable IOMMU on both vendors (harmless to pass both);
  # iommu=pt = passthrough mode for better perf
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2860,10de:22bd"
    # If you later hit BAR reservation issues, try also:
    # "video=efifb:off"
  ];

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = false;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  users.groups.libvirtd.members = [ "anuramat" ];
  users.users.anuramat.extraGroups = [ "libvirtd" ];
}
