{ config, ... }:
{
  plugins = {
    mini-align.enable = true;
    mini-ai = {
      enable = true;
      # treesitter-textobjects only provides the queries; selection goes
      # through mini.ai (f/a override the pattern-based builtins)
      settings.custom_textobjects =
        let
          spec = captures: { __raw = "require('mini.ai').gen_spec.treesitter(${captures})"; };
        in
        {
          F = spec "{ a = '@function.outer', i = '@function.inner' }";
          o = spec "{ a = { '@conditional.outer', '@loop.outer' }, i = { '@conditional.inner', '@loop.inner' } }";
          f = spec "{ a = '@call.outer', i = '@call.inner' }";
          a = spec "{ a = '@parameter.outer', i = '@parameter.inner' }";
        };
    };
    mini-bracketed.enable = true;
    aerial.enable = true;
    diffview.enable = true;
    nvim-surround.enable = true;
    harpoon.enable = true;
  };

  globals = {
    nvim_surround_no_normal_mappings = true;
    nvim_surround_no_insert_mappings = true;
    nvim_surround_no_visual_mappings = true;
  };
  keymaps =
    let
      inherit (config.lib) keymap;
    in
    [
      (keymap "n" "<leader>ha" { __raw = ''function() require("harpoon"):list():add() end''; } "Add")
      (keymap "n" "<leader>hl" {
        __raw = ''function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end'';
      } "List")
      (keymap "n" "<leader>hn" { __raw = ''function() require("harpoon"):list():next() end''; } "Next")
      (keymap "n" "<leader>hp" {
        __raw = ''function() require("harpoon"):list():prev() end'';
      } "Previous")

      (keymap "i" "<C-g>s" "<Plug>(nvim-surround-insert)" null)
      (keymap "i" "<C-g>S" "<Plug>(nvim-surround-insert-line)" null)
      (keymap "n" "s" "<Plug>(nvim-surround-normal)" null)
      (keymap "n" "ss" "<Plug>(nvim-surround-normal-cur)" null)
      (keymap "n" "S" "<Plug>(nvim-surround-normal-line)" null)
      (keymap "n" "SS" "<Plug>(nvim-surround-normal-cur-line)" null)
      (keymap "x" "s" "<Plug>(nvim-surround-visual)" null)
      (keymap "x" "S" "<Plug>(nvim-surround-visual-line)" null)
      (keymap "n" "ds" "<Plug>(nvim-surround-delete)" null)
      (keymap "n" "cs" "<Plug>(nvim-surround-change)" null)
      (keymap "n" "cS" "<Plug>(nvim-surround-change-line)" null)
    ];
}
