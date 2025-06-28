{ hax, ... }:
{
  plugins = {
    # mini-bracketed.enabled = true;
    # mini-align.enabled = true;
    # mini-ai.enabled = true;

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
      inherit (hax.vim) luaf;
      set = key: hax.vim.set ("<leader>h" + key);
    in
    [
      (set "a" (luaf "require('harpoon'):list():add()") "Add")
      (set "l" (luaf "require('harpoon').ui:toggle_quick_menu(m:list())") "List")
      (set "n" (luaf "require('harpoon'):list():next()") "Next")
      (set "p" (luaf "require('harpoon'):list():prev()") "Previous")
    ];
}
