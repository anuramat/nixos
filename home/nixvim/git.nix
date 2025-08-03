{ lib, hax, ... }:
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
      set =
        key: action: hax.vim.set "<leader>g${key}" "<cmd>Gitsigns ${action}<cr>" "${action} [Gitsigns]";
    in
    [
      {
        mode = "v";
        key = "<leader>gs";
        action = "<cmd>stage_hunk";
        options = {
          desc = "stage selection";
        };
      }
      (set "s" "stage_hunk")
      (set "S" "stage_buffer")
      (set "r" "reset_hunk")
      (set "R" "reset_buffer")
      (set "b" "blame_line")
      (set "p" "preview_hunk")
      (set "d" "diffthis")

      (hax.vim.set "]h" "<cmd>Gitsigns next_hunk<cr>" "next hunk")
      (hax.vim.set "[h" "<cmd>Gitsigns prev_hunk<cr>" "previous hunk")

      {
        mode = [
          "o"
          "x"
        ];
        key = "ih";
        action.__raw = "function() require('gitsigns').select_hunk() end";
        options.desc = "Inside hunk [gitsigns]";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "ah";
        action.__raw = "function() require('gitsigns').select_hunk({ greedy = true }) end";
        options.desc = "Around hunk [gitsigns]";
      }
    ];
}
