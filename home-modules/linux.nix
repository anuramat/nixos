{ pkgs, ... }:
{
  home.packages = with pkgs; [

    zenith-nvidia # top WITH nvidia GPUs
    nvitop # nvidia gpu

    mermaid-filter
    bubblewrap # sandboxing

    parted
    geteduroam-cli
    wine
    distrobox
    wayidle # runs a command on idle (one-off, thus orthogonal to swayidle)
    subcat
    trashy # `trash`

    # hardware
    acpi # battery status etc
    dmidecode # read hw info from bios using smbios/dmi
    efibootmgr # EFI boot manager editor
    hwinfo
    libva-utils # vainfo - info on va-api
    lm_sensors
    lshw # hw info
    nvme-cli
    smem # ram usage
    v4l-utils # camera stuff
    wirelesstools # iwconfig etc
  ];

  # TODO figure out rust version or keyring locking
  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  programs.wayprompt.enable = true;
  services.gpg-agent = {
    pinentry = {
      package = pkgs.wayprompt;
      program = "pinentry-wayprompt";
    };
  };
}
