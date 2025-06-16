{
  # TODO outline.aerial-nvim.enable = true;
  # TODO diffview-nvim.enable = true;
  plugins = {
    mini = {
      enable = true;
      modules = {
        align = { };
        bracketed = { };
      };
    };

    image = {
      enable = true;
      settings.backend = "kitty";
    };

    aerial.enable = true;
    diffview.enable = true;

    nvim-surround = {
      enable = true;
      settings = {
        keymaps = {
          insert = "<C-g>s";
          insert_line = "<C-g>S";
          normal = "s";
          normal_cur = "ss";
          normal_line = "S";
          normal_cur_line = "SS";
          visual = "s";
          visual_line = "S";
          delete = "ds";
          change = "cs";
          change_line = "cS";
        };
      };
    };
  };
}
