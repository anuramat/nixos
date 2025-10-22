{ hax, ... }:
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
      set = key: action: hax.vim.set "<leader>g${key}" "Gitsigns ${action}" "${action} [Gitsigns]";
    in
    [
      # stage
      {
        mode = "v";
        key = "<leader>gs";
        action = hax.vim.luaf ''gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })'';
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
        action = hax.vim.luaf ''gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })'';
        options = {
          desc = "reset selection";
        };
      }
      (set "r" "reset_hunk")
      (set "R" "reset_buffer")

      # navigation
      (hax.vim.set "]h" "Gitsigns next_hunk" "next hunk")
      (hax.vim.set "[h" "Gitsigns prev_hunk" "previous hunk")

      # text objects
      {
        mode = [
          "o"
          "x"
        ];
        key = "ih";
        action = hax.vim.luaf ''require("gitsigns").select_hunk()'';
        options.desc = "Inside hunk [gitsigns]";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "ah";
        action = hax.vim.luaf ''require("gitsigns").select_hunk({ greedy = true })'';
        options.desc = "Around hunk [gitsigns]";
      }

      # misc
      (set "b" "blame_line")
      (set "p" "preview_hunk")
      (set "d" "diffthis")
    ];
}
