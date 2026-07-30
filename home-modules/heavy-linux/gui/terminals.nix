{
  programs = {
    ghostty = {
      # cons: slowest startup
      # pros: supports kitty image protocol; almost zero config; not bloated
      enable = true;
      clearDefaultKeybinds = true;
      settings = {
        # TODO emoji font doesn't work
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
  };
}
