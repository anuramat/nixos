{
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

  plugins.harpoon.enable = true;
  keymaps =
    let
      map = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
      mapWrap = key: action: map "<leader>g${key}" "<cmd>Gitsigns ${action}<cr>" "${action} [Gitsigns]";
    in
    [
      (mapWrap "a" "function(m) m:list():add() end" "Add")
      (mapWrap "l" "function(m) m.ui:toggle_quick_menu(m:list()) end" "List")
      (mapWrap "n" "function(m) m:list():next() end" "Next")
      (mapWrap "p" "function(m) m:list():prev() end" "Previous")
    ];
}
