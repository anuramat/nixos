{
  vim = {
    mini = {
      align.enable = true;
      bracketed.enable = true;
    };
    utility = {
      images.image-nvim = {
        enable = true;
        setupOpts.backend = "kitty";
      };
      outline.aerial-nvim.enable = true;
      diffview-nvim.enable = true;
      surround = {
        enable = true;
        useVendoredKeybindings = false;
        setupOpts = {
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
  };
}
