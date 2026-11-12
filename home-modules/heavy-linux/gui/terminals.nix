{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  # emoji presentation: use the (monochrome) emoji font instead of the embedded color one
  ghostty = pkgs.ghostty.overrideAttrs { patches = [ ./ghostty-emoji.patch ]; };
  # with prime offload, glvnd picks the nvidia EGL, whose dmabufs the iGPU compositor rejects: black window;
  # a wrapper instead of a postFixup, so that it doesn't rebuild ghostty
  mesaGhostty = pkgs.symlinkJoin {
    inherit (ghostty) name meta;
    paths = [ ghostty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ghostty \
        --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      # the services exec the binary by its store path
      for f in $out/share/systemd/user/*.service $out/share/dbus-1/services/*.service; do
        cp --remove-destination "$(readlink "$f")" "$f"
        substituteInPlace "$f" --replace-fail ${ghostty} $out
      done
    '';
  };
in
{
  # start the background instance with the session, so the first window opens fast too
  xdg.configFile."systemd/user/${config.wayland.systemd.target}.wants/app-com.mitchellh.ghostty.service".source =
    "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";
  programs = {
    ghostty = {
      # cons: slowest startup
      # pros: supports kitty image protocol; almost zero config; not bloated
      enable = true;
      package =
        if osConfig != null && osConfig.hardware.nvidia.prime.offload.enable then mesaGhostty else ghostty;
      clearDefaultKeybinds = true;
      settings = {
        cursor-style = "block";
        cursor-style-blink = "false";
        resize-overlay = "never";
        title = "ghostty";
        gtk-single-instance = true;
        confirm-close-surface = false;
        command = "bash -l";
        window-decoration = "false";

        keybind = [

          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"

          "ctrl+shift+n=new_window"

          "ctrl+shift+f=start_search"

          "ctrl+equal=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+zero=reset_font_size"

          "page_up=scroll_page_up"
          "page_down=scroll_page_down"
          "home=scroll_to_top"
          "end=scroll_to_bottom"
        ];
      };
    };
  };
  home.sessionVariables.TERMCMD = lib.getExe config.programs.ghostty.package;
  # TERMCMD = "${lib.getExe pkgs.kitty} -1";
}
