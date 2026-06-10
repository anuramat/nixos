{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [

      zenith-nvidia # top WITH nvidia GPUs
      nvitop # nvidia gpu

      bubblewrap # sandboxing
      fuse-overlayfs

      parted
      geteduroam-cli
      distrobox
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

    ]
    ++ lib.optionals config.gui [
      seahorse
      wayidle # runs a command on idle (one-off, thus orthogonal to swayidle)
      wine
    ];

  services.pss.enable = true; # secret service api -- exposes password-store over dbus
  programs.wayprompt.enable = config.gui;
  services.gpg-agent = {
    pinentry =
      if config.gui then
        let
          name = "pinentry-auto";
          package = pkgs.writeShellApplication {
            inherit name;
            runtimeInputs = [
              pkgs.wayprompt
              pkgs.pinentry-tty
            ];
            # DISPLAY check so that it still works over ssh
            text = ''
              if [ -v DISPLAY ]; then
                exec ${pkgs.wayprompt}/bin/pinentry-wayprompt "$@"
              else
                exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
              fi
            '';
          };
        in
        {
          inherit package;
          program = name;
        }
      else
        {
          package = pkgs.pinentry-tty;
          program = "pinentry-tty";
        };
  };
}
