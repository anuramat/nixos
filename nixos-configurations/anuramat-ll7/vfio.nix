{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # RTX 4070 Mobile and its HDMI audio, IOMMU group 13
  gpuIds = "10de:2860,10de:22bd";

  # must match the client version
  lgHost = pkgs.fetchurl {
    name = "looking-glass-host.zip";
    url = "https://looking-glass.io/artifact/${pkgs.looking-glass-client.version}/host";
    hash = "sha256-wkFaWgxAXx1qqTaYa91LgGxQV0tFIXR+ETw74r4Eexs=";
  };
  unattend =
    pkgs.runCommand "win11-unattend.iso"
      {
        nativeBuildInputs = with pkgs; [
          xorriso
          unzip
        ];
      }
      ''
        mkdir d
        cp ${./win11/autounattend.xml} d/autounattend.xml
        sed 's/$/\r/' ${./win11/setup.cmd} > d/setup.cmd
        unzip -j ${lgHost} looking-glass-host-setup.exe -d d
        xorriso -as mkisofs -J -r -V UNATTEND -o $out d
      '';
  domain = pkgs.replaceVars ./win11/domain.xml {
    virtio = pkgs.virtio-win.src;
    inherit unattend;
  };
in
{
  # separate boot entry with the dGPU bound to vfio-pci for a VM;
  # the default entry keeps it for CUDA and PRIME offload
  specialisation.vfio.configuration = {
    system.nixos.tags = [ "vfio" ];

    # keep the nvidia driver away from the card; the panel stays on the iGPU
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

      # looking glass shared memory: 2560x1600 SDR frames need ~42MB, rounded up
      extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
      kernelModules = [ "kvmfr" ];
      extraModprobeConfig = "options kvmfr static_size_mb=64";
    };
    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${inputs.self.consts.user.username}", GROUP="kvm", MODE="0660"
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
    };
    # (re)define the VM from the repo; the disk is created once
    systemd.services.win11-define = {
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with config.virtualisation.libvirtd; [
        package
        qemu.package
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        img=/var/lib/libvirt/images/win11.qcow2
        mkdir -p "$(dirname "$img")"
        [ -e "$img" ] || qemu-img create -f qcow2 "$img" 512G
        virsh define ${domain}
      '';
    };
    programs.virt-manager.enable = true;
    users.users.${inputs.self.consts.user.username}.extraGroups = [
      "libvirtd"
      "kvm"
    ];
    environment.systemPackages = [ pkgs.looking-glass-client ];
  };
}
