# windows 11 VM with the passed-through 4070, installed unattended on the
# first boot without its disk; only the Windows ISO is provided by hand, at
# /var/lib/libvirt/images/win11.iso
{ config, pkgs, ... }:
let
  images = "/var/lib/libvirt/images";

  fetchzip =
    url: hash:
    pkgs.fetchzip {
      inherit url hash;
      extension = "zip"; # the looking glass URL doesn't end in .zip
      stripRoot = false;
    };
  # must match the client version
  lgHost = fetchzip "https://looking-glass.io/artifact/${pkgs.looking-glass-client.version}/host" "sha256-u6HTpiWrfY0u4y39YFzL/Ok/pvY++tixfRo92a4zJZw=";
  nvidia = pkgs.fetchurl {
    url = "https://us.download.nvidia.com/Windows/621.14/621.14-notebook-win10-win11-64bit-international-dch-whql.exe";
    hash = "sha256-mGewyGiZcsQZiFk1uzhtmZr/+jOv1RTK2zhO6E7809M=";
  };
  # virtual display driver; despite the name, the driver is amd64
  vdd = fetchzip "https://github.com/VirtualDrivers/Virtual-Display-Driver/releases/download/25.7.23/VirtualDisplayDriver-x86.Driver.Only.zip" "sha256-TTEeagtnEAoUiFZqFog183NAGIOe8kCmTm1p5wVIfa0=";
  # creates the root device that the virtual display driver binds to
  nefcon = fetchzip "https://github.com/nefarius/nefcon/releases/download/v1.21.1/nefcon_v1.21.1.zip" "sha256-xh/aeN+TkqfQAK6ASH7QpbTn4CAUnKA48QZCJ8LJd8U=";

  unattend =
    pkgs.runCommand "win11-unattend.iso"
      {
        nativeBuildInputs = [
          pkgs.xorriso
          pkgs.perl
        ];
      }
      ''
        mkdir -p d/vdd
        cp ${./autounattend.xml} d/autounattend.xml
        cp ${./setup.ps1} d/setup.ps1
        cp ${lgHost}/looking-glass-host-setup.exe ${nefcon}/x64/nefconc.exe d/
        cp ${nvidia} d/nvidia.exe
        cp ${vdd}/VirtualDisplayDriver/{MttVDD.inf,MttVDD.dll,mttvdd.cat} d/vdd/
        # the panel's 3200x2000 as the only mode, so that windows uses it; the
        # global refresh rates include 165
        perl -0pe 's|<resolutions>.*</resolutions>|<resolutions><resolution><width>3200</width><height>2000</height><refresh_rate>165</refresh_rate></resolution></resolutions>|s' \
          ${vdd}/VirtualDisplayDriver/vdd_settings.xml > d/vdd/vdd_settings.xml
        xorriso -as mkisofs -J -r -V UNATTEND -o $out d
      '';

  # vga only for the install: looking glass needs the 4070 to be the only display
  vga = ''
    <model type="vga"/>
    <!-- off 00:01, which would shift the root ports, so that the 4070 would
         come back without its driver as a new device once vga is gone -->
    <address type="pci" domain="0x0000" bus="0x00" slot="0x10" function="0x0"/>
  '';
  none = ''<model type="none"/>'';
  domain =
    video:
    pkgs.replaceVars ./domain.xml {
      inherit unattend video;
      virtio = pkgs.virtio-win.src;
    };

  path = with config.virtualisation.libvirtd; [
    package
    qemu.package
  ];
in
{
  systemd.services = {
    # (re)define the VM from the repo, or install it if there's no disk
    win11-define = {
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      inherit path;
      serviceConfig.Type = "oneshot";
      script = ''
        if [ -e ${images}/win11.qcow2 ]; then
          virsh define ${domain none}
        else
          systemctl start --no-block win11-install
        fi
      '';
    };

    # to reinstall, delete the disk and restart win11-define
    win11-install = {
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      inherit path;
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "3h";
      };
      script = ''
        img=${images}/win11.qcow2
        if [ ! -e ${images}/win11.iso ]; then
          echo "put the Windows 11 ISO at ${images}/win11.iso, then restart win11-define"
          exit 1
        fi
        qemu-img create -f qcow2 "$img" 512G
        virsh define ${domain vga}

        # windows asks to press a key to boot from the ISO; until setup
        # starts writing the disk, reboot and press Enter through the prompt
        for attempt in 1 2 3 4 5; do
          virsh start win11 || virsh reset win11
          for i in $(seq 30); do sleep 0.5; virsh send-key win11 KEY_ENTER >/dev/null; done
          sleep 120
          [ "$(du -k "$img" | cut -f1)" -gt 100000 ] && break
        done

        # setup.ps1 shuts the guest down when it's done
        until [ "$(virsh domstate win11)" = "shut off" ]; do sleep 10; done
        virsh define ${domain none}
        virsh start win11
      '';
    };
  };
}
