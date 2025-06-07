let
  font-family = "Hack Nerd Font";
  font-size = "13";
in
{
  programs = {
    foot = {
      enable = true;
      settings = {
        main.font = "Hack Nerd Font:size=13";

        scrollback.lines = 13337;

        bell.urgent = "yes";
        bell.visual = "yes";
        bell.notify = "no";

        key-bindings.show-urls-copy = "Control+Shift+y";
        key-bindings.scrollback-home = "Shift+Home";
        key-bindings.scrollback-end = "Shift+End";
      };
    };
    ghostty = {
      enable = true;
      clearDefaultKeybinds = true;
      settings = {
        inherit font-size font-family;
        cursor-style = "block";
        cursor-style-blink = "false";
        shell-integration-features = "no-cursor";
        resize-overlay = "never";
        window-decoration = "false";
      };
    };
    kitty = {
      enable = true;
      settings = {
        font_family = "Hack Nerd Font Regular";
        font_size = 13;
        confirm_os_window_close = 0;
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_bar_align = "left";
        tab_powerline_style = "slanted";
        macos_option_as_alt = "yes";
        macos_traditional_fullscreen = "yes";
      };
    };
  };
}
