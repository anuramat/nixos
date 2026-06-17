{ config, lib, ... }:
{
  plugins = {
    gitlinker.enable = true;
    fugitive.enable = true;

    gitsigns = {
      enable = true;
      settings = {
        sign_priority = 1000;
        signs_staged =
          lib.genAttrs
            [
              "add"
              "change"
              "delete"
              "topdelete"
              "changedelete"
              "untracked"
            ]
            (_: {
              text = "▎";
            });
      };
    };
  };

  keymaps =
    let
      inherit (config.lib) keymap luaf cmd;
      setAction = key: action: cmd "n" key "Gitsigns ${action}" "gitsigns: ${action}";
    in
    [
      # stage
      (keymap "v" "<leader>gs"
        (luaf ''require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })'')
        "gitsigns: stage selection"
      )
      (setAction "<leader>gs" "stage_hunk")
      (setAction "<leader>gS" "stage_buffer")

      # reset
      (keymap "v" "<leader>gr"
        (luaf ''require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })'')
        "gitsigns: reset selection"
      )
      (setAction "<leader>gr" "reset_hunk")
      (setAction "<leader>gR" "reset_buffer")

      # navigation
      (setAction "]h" "next_hunk")
      (setAction "[h" "prev_hunk")

      # text objects
      (keymap [
        "o"
        "x"
      ] "ih" (luaf ''require("gitsigns").select_hunk()'') "gitsigns: inside hunk")
      (keymap [
        "o"
        "x"
      ] "ah" (luaf ''require("gitsigns").select_hunk({ greedy = true })'') "gitsigns: around hunk")

      # misc
      (setAction "<leader>gb" "blame_line")
      (setAction "<leader>gp" "preview_hunk")
      (setAction "<leader>gd" "diffthis")
    ];
}
