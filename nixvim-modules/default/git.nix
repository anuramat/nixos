{ config, ... }:
{
  plugins = {
    gitlinker = {
      enable = true;
    };

    fugitive = {
      enable = true;
    };

    gitsigns = {
      enable = true;
      settings = {
        sign_priority = 1000;
        signs_staged = {
          add = {
            text = "▎";
          };
          change = {
            text = "▎";
          };
          delete = {
            text = "▎";
          };
          topdelete = {
            text = "▎";
          };
          changedelete = {
            text = "▎";
          };
          untracked = {
            text = "▎";
          };
        };
      };
    };
  };

  keymaps =
    let
      inherit (config.lib) keymap luaf;
      setAction = key: action: keymap "n" key "<cmd>Gitsigns ${action}<cr>" "gitsigns: ${action}";
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
        (config.lib.luaf ''require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })'')
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
      ] "ih" (config.lib.luaf ''require("gitsigns").select_hunk()'') "gitsigns: inside hunk")
      (keymap
        [
          "o"
          "x"
        ]
        "ah"
        (config.lib.luaf ''require("gitsigns").select_hunk({ greedy = true })'')
        "gitsigns: around hunk"
      )

      # misc
      (setAction "<leader>gb" "blame_line")
      (setAction "<leader>gp" "preview_hunk")
      (setAction "<leader>gd" "diffthis")
    ];
}
