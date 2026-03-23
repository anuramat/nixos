{
  programs = {
    ghostty = {
      # cons: slowest startup
      # pros: supports kitty image protocol; almost zero config; not bloated
      enable = true;
      clearDefaultKeybinds = true;
      settings = {
        cursor-style = "block";
        cursor-style-blink = "false";
        resize-overlay = "never";
        title = "ghostty";
        gtk-single-instance = true;
        confirm-close-surface = false;

        keybind = [

          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"

          "ctrl+shift+n=new_window"

          "ctrl+shift+f=start_search"

          "page_up=scroll_page_up"
          "page_down=scroll_page_down"
          "home=scroll_to_top"
          "end=scroll_to_bottom"
        ];
      };
    };
    kitty = {
      # cons: medium startup time; bloated
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
