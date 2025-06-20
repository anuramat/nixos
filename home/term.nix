{
  programs = {
    foot = {
      enable = true;
      settings = {
        scrollback.lines = 13337;
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
    ghostty = {
      enable = true;
      clearDefaultKeybinds = true;
      settings = {
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
