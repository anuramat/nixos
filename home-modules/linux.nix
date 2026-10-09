{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bubblewrap # sandboxing
    fuse-overlayfs

    btrfs-progs
    cryptsetup # luks etc
    percollate # html to markdown

    parted
    subcat
    trashy # `trash`
  ];

  services.pss.enable = true; # secret service api -- exposes password-store over dbus
  programs.wayprompt.enable = config.gui == "wayland";
  services.gpg-agent = {
    pinentry =
      if config.gui == "wayland" then
        {
          package = pkgs.writeShellApplication {
            name = "pinentry-auto";
            # DISPLAY check so that it still works over ssh
            text = ''
              if [ -v DISPLAY ]; then
                exec ${pkgs.wayprompt}/bin/pinentry-wayprompt "$@"
              else
                exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
              fi
            '';
          };
        }
      else
        {
          package = pkgs.pinentry-tty;
          program = "pinentry-tty";
        };
  };
}
