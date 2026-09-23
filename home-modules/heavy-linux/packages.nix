{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
