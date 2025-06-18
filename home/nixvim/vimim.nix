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
      settings = {
        backend = "kitty";
        only_render_image_at_cursor = true;
        integrations.markdown.only_render_image_at_cursor = true;
      };
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
      _mkMap =
        key: action: desc:
        {
          mode = "n";
          inherit key action;
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
      mkMap =
        k: a: d:
        _mkMap ("<leader>hk") a d;
    in
    [
      (mkMap "a" { __raw = "function() require('harpoon'):list():add() end"; } "Add")
      (mkMap "l" { __raw = "function() require('harpoon').ui:toggle_quick_menu(m:list()) end"; } "List")
      (mkMap "n" { __raw = "function() require('harpoon'):list():next() end"; } "Next")
      (mkMap "p" { __raw = "function() require('harpoon'):list():prev() end"; } "Previous")
    ];
}
