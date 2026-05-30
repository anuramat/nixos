{ config, ... }:
{
  plugins = {
    # TODO enable when available (in 25.11?)
    # mini-align.enable = true;
    # mini-ai.enable = true;
    aerial.enable = true;
    diffview.enable = true;
    nvim-surround.enable = true;
  };

  globals = {
    nvim_surround_no_normal_mappings = true;
    nvim_surround_no_insert_mappings = true;
    nvim_surround_no_visual_mappings = true;
  };
  plugins.harpoon.enable = true;
  keymaps =
    let
      inherit (config.lib) luaf keymap;
    in
    [
      (keymap "n" "<leader>ha" (luaf ''require("harpoon"):list():add()'') "Add")
      (keymap "n" "<leader>hl" (luaf ''require("harpoon").ui:toggle_quick_menu(m:list())'') "List")
      (keymap "n" "<leader>hn" (luaf ''require("harpoon"):list():next()'') "Next")
      (keymap "n" "<leader>hp" (luaf ''require("harpoon"):list():prev()'') "Previous")

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
