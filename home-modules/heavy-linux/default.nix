{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./agents
    ./desktop
    ./gui
    ./ssh-mic.nix
    ./terminals.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  stylix.icons =
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

  gui = true;

  # https://github.com/artemsen/swayimg/blob/master/CONFIG.md
  xdg.configFile."swayimg/init.lua".text = # lua
    ''
      local function trash(mode)
        return function()
          local img = mode.get_image()
          if not img then return end
          os.execute("${lib.getExe pkgs.trashy} -- '" .. img.path:gsub("'", "'\"'\"'") .. "'")
          swayimg.imagelist.remove(img.path)
          swayimg.text.status = "File removed: " .. img.path
        end
      end
      swayimg.viewer.on_key("Shift+Delete", trash(swayimg.viewer))
      swayimg.gallery.on_key("Shift+Delete", trash(swayimg.gallery))

      -- in total uses about 1.6 GB of RAM
      swayimg.viewer.preload = 10
      swayimg.viewer.history = 10
      swayimg.gallery.preload = true
      swayimg.gallery.cache = 500
      swayimg.gallery.embedded_thumb = true
    '';

  home.packages = with pkgs; [
    swayimg
    cudaPackages.cuda_nvcc
    fontpreview

    # settings
    ddcutil # configure external monitors (eg brightness)
    crosspipe # pipewire graph
    networkmanagerapplet # networking
    pavucontrol # audio
    pulseaudio
    system-config-printer # printer
    wdisplays # GUI kanshi config generator

    # screen capture
    grim # barebones screenshot tool
    hyprpicker # color picker
    satty # screenshot markup
    shotman # screenshot, with simple preview afterwards, no markup
    slurp # select screen region
    swappy # screenshot markup
    gpu-screen-recorder # wf-recorder but uses GPU

    alsa-utils
    cheese # webcam
    libva-utils # vainfo - info on va-api
    v4l-utils # camera stuff
    j4-dmenu-desktop # .desktop wrapper for dmenus
    libnotify # notify-send etc
    # mesa-demos # some 3d demos, useful for graphics debugging
    proton-pass # password manager
    waypipe # gui forwarding
    remmina # vnc client
    wayvnc # vnc server
    wev # wayland event viewer, useful for debugging
    wl-clip-persist # otherwise clipboard contents disappear on exit
    wl-clipboard # wl-copy/wl-paste: copy from stdin/paste to stdout
    wl-mirror # screen mirroring
    wmenu # dmenu 1to1
    dragon-drop # terminal drag and drop
  ];
}
