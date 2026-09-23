# physical linux machines
{ pkgs, ... }:
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
    geteduroam-cli
    wavemon # wifi signal plot
    wirelesstools # iwconfig etc
  ];
}
