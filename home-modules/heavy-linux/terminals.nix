{
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
}
