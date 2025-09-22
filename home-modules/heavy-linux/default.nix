{ pkgs, lib, ... }:
{
  imports = [
    ./agents
    ./desktop
  ];

  stylix.iconTheme =
    let
      dark = "Dracula";
    in
    {
      enable = true;
      inherit dark;
      light = dark; # TODO find a light theme
      package = pkgs.dracula-icon-theme;
      # package = pkgs.xfce.xfce4-icon-theme;
    };

  programs.swayimg = {
    enable = true;
    settings =
      let
        binds = {
          "Shift+Delete" = ''exec ${lib.getExe pkgs.trashy} -- '%' && echo "File removed: %"; skip_file'';
        };
      in
      {
        "keys.viewer" = binds;
        "keys.galllery" = binds;
      };
  };

  programs.ghostty.settings.window-decoration = "false";
  programs.foot = {
    enable = true;
    settings = {
      scrollback.lines = 133337;
      bell = {
        urgent = "yes";
        visual = "yes";
        notify = "no";
      };
      key-bindings = {
        show-urls-copy = "Control+Shift+y";
        scrollback-home = "Shift+Home";
        scrollback-end = "Shift+End";
      };
    };
  };

  home.packages = with pkgs; [
    # settings
    ddcutil # configure external monitors (eg brightness)
    helvum # pipewire patchbay
    networkmanagerapplet # networking
    pavucontrol # audio
    system-config-printer # printer
    wdisplays # GUI kanshi config generator

    # screen capture
    grim # barebones screenshot tool
    hyprpicker # color picker
    satty # screenshot markup
    shotman # screenshot, with simple preview afterwards, no markup
    slurp # select screen region
    swappy # screenshot markup
    wf-recorder # CLI screen capture

    alsa-utils
    bemenu # slightly better -- has dynamic height
    cheese # webcam
    j4-dmenu-desktop # .desktop wrapper for dmenus
    libnotify # notify-send etc
    mesa-demos # some 3d demos, useful for graphics debugging
    proton-pass # password manager
    steam
    waypipe # gui forwarding
    wev # wayland event viewer, useful for debugging
    wl-clip-persist # otherwise clipboard contents disappear on exit
    wl-clipboard # wl-copy/wl-paste: copy from stdin/paste to stdout
    wl-mirror # screen mirroring
    wmenu # dmenu 1to1
    dragon-drop # terminal drag and drop
  ];
}
