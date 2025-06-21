{ hax, ... }:
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
        settings.integrations.markdown.enabled = false;
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
      set =
        k: a: d:
        hax.vim.set ("<leader>h" + k) a d;
    in
    [
      (set "a" { __raw = "function() require('harpoon'):list():add() end"; } "Add")
      (set "l" { __raw = "function() require('harpoon').ui:toggle_quick_menu(m:list()) end"; } "List")
      (set "n" { __raw = "function() require('harpoon'):list():next() end"; } "Next")
      (set "p" { __raw = "function() require('harpoon'):list():prev() end"; } "Previous")
    ];
}
