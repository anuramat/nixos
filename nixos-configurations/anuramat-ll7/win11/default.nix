# windows 11 VM with the passed-through 4070, installed unattended on the
# first boot without its disk; only the Windows ISO is provided by hand, see iso
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  images = "/var/lib/libvirt/images";

  fetchzip =
    url: hash:
    pkgs.fetchzip {
      inherit url hash;
      extension = "zip"; # the looking glass URL doesn't end in .zip
      stripRoot = false;
    };
  iso = pkgs.requireFile {
    name = "win11.iso";
    hash = "sha256-vUMH3zK8ivM7OczssRdK6zRThmMPiaK4bHpONrVeplA=";
    message = ''
      Download the Windows 11 (multi-edition, English, x64) ISO from
      https://www.microsoft.com/software-download/windows11, rename it to
      win11.iso, and add it with `nix-store --add-fixed sha256 win11.iso`
    '';
  };

  # looking glass host version installed in the guest, which the client must
  # match; like stateVersion, it's bumped by hand: install the new host in the
  # guest (https://looking-glass.io/artifact/VERSION/host), then update this
  # and the hash below
  lgVersion = "B7";
  lgClient =
    config.home-manager.users.${inputs.self.consts.user.username}.programs.looking-glass-client.package;
  lgHost = fetchzip "https://looking-glass.io/artifact/${lgVersion}/host" "sha256-u6HTpiWrfY0u4y39YFzL/Ok/pvY++tixfRo92a4zJZw=";
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
        # the panel's 3200x2000@165 as the only mode, so that windows uses it;
        # the global refresh rates apply to every resolution
        perl -0pe 's|<global>.*</global>|<global><g_refresh_rate>165</g_refresh_rate></global>|s;
          s|<resolutions>.*</resolutions>|<resolutions><resolution><width>3200</width><height>2000</height><refresh_rate>165</refresh_rate></resolution></resolutions>|s' \
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
      inherit iso unattend video;
      virtio = pkgs.virtio-win.src;
    };

  path = with config.virtualisation.libvirtd; [
    package
    qemu.package
  ];
in
{
  assertions = [
    {
      assertion = lgClient.version == lgVersion;
      message = "looking-glass-client is ${lgClient.version}, but the win11 guest's host is ${lgVersion}; see lgVersion in nixos-configurations/anuramat-ll7/win11/default.nix";
    }
  ];

  # click-to-capture latency benchmark, see ./latency.py
  environment.systemPackages = [
    (pkgs.writers.writePython3Bin "win11-latency" {
      libraries = with pkgs.python3Packages; [
        evdev
        # with bindings for wlr-screencopy, which it doesn't ship
        (pywayland.overridePythonAttrs (_: {
          postPatch = ''
            substituteInPlace setup.py --replace-fail \
              'input_files = [self.xml_file]' \
              'input_files = [self.xml_file, "${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-screencopy-unstable-v1.xml"]'
          '';
        }))
      ];
      flakeIgnore = [ "E501" ];
    } ./latency.py)
  ];

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
        # drop the previous install's UEFI variables and TPM state, if any
        virsh undefine --nvram --tpm win11 || true
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
