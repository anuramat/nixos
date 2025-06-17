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
      mkMap =
        key: action: desc:
        {
          mode = "n";
          key = "key";
          inherit action;
        }
        // (
          if builtins.typeOf action == "string" then
            {
              action = "<cmd>${action}<cr>";
              desc = action;
            }
          else
            { }
        );
    in
    [
      (mkMap "a" { __raw = "function(m) m:list():add() end"; } "Add")
      (mkMap "l" { __raw = "function(m) m.ui:toggle_quick_menu(m:list()) end"; } "List")
      (mkMap "n" { __raw = "function(m) m:list():next() end"; } "Next")
      (mkMap "p" { __raw = "function(m) m:list():prev() end"; } "Previous")
    ];
}
