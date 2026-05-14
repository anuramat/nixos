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
      set = key: action: config.lib.set "<leader>g${key}" "Gitsigns ${action}" "${action} [Gitsigns]";
    in
    [
      # stage
      {
        mode = "v";
        key = "<leader>gs";
        action = config.lib.luaf ''require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })'';
        options = {
          desc = "stage selection";
        };
      }
      (set "s" "stage_hunk")
      (set "S" "stage_buffer")

      # reset
      {
        mode = "v";
        key = "<leader>gr";
        action = config.lib.luaf ''require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })'';
        options = {
          desc = "reset selection";
        };
      }
      (set "r" "reset_hunk")
      (set "R" "reset_buffer")

      # navigation
      (config.lib.set "]h" "Gitsigns next_hunk" "next hunk")
      (config.lib.set "[h" "Gitsigns prev_hunk" "previous hunk")

      # text objects
      {
        mode = [
          "o"
          "x"
        ];
        key = "ih";
        action = config.lib.luaf ''require("gitsigns").select_hunk()'';
        options.desc = "Inside hunk [gitsigns]";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "ah";
        action = config.lib.luaf ''require("gitsigns").select_hunk({ greedy = true })'';
        options.desc = "Around hunk [gitsigns]";
      }

      # misc
      (set "b" "blame_line")
      (set "p" "preview_hunk")
      (set "d" "diffthis")
    ];
}
