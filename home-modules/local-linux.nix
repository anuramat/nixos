# physical linux machines
{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    # hardware
    acpi # battery status etc
    dmidecode # read hw info from bios using smbios/dmi
    efibootmgr # EFI boot manager editor
    hwinfo
    lm_sensors
    lshw # hw info
    nvme-cli
    pciutils
    smem # ram usage
    usbutils

    # wifi
    wavemon # wifi signal plot
    wirelesstools # iwconfig etc

    # gphoto2 over PTP/IP, with the camera found through mDNS; the camera
    # accepts only the paired client GUID, which libgphoto2 reads only from
    # its settings file (it also writes to it)
    (writeShellApplication {
      name = "nikon-gphoto2";
      runtimeInputs = [
        avahi
        gphoto2
      ];
      text = ''
        ip=$(avahi-browse -rpt _ptp._tcp | awk -F';' '$1 == "=" && $3 == "IPv4" { print $8; exit }')
        [ -n "$ip" ] || { echo 'camera not found' >&2; exit 1; }
        settings=${config.xdg.configHome}/gphoto/settings
        guid=$(tr -d '\n:-' <${config.lib.secrets.nikon.path} | sed 's/../&:/g; s/:$//')
        mkdir -p "$(dirname "$settings")"
        touch "$settings"
        sed -i '/^ptp2_ip=guid=/d' "$settings"
        echo "ptp2_ip=guid=$guid" >>"$settings"
        exec gphoto2 --port "ptpip:$ip" --camera 'PTP/IP Camera' "$@"
      '';
    })
  ];
}
