{ lib, ... }:
{
  plugins = {
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
      map = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
    in
    [
      (map "<leader>gs" "<cmd>Gitsigns stage_hunk<cr>" "stage hunk")
      (map "<leader>gS" "<cmd>Gitsigns stage_buffer<cr>" "stage buffer")
      (map "<leader>gr" "<cmd>Gitsigns reset_hunk<cr>" "reset hunk")
      (map "<leader>gR" "<cmd>Gitsigns reset_buffer<cr>" "reset buffer")
      (map "<leader>gb" "<cmd>Gitsigns blame_line<cr>" "blame line")
      (map "<leader>gp" "<cmd>Gitsigns preview_hunk<cr>" "preview hunk")
      (map "<leader>gd" "<cmd>Gitsigns diffthis<cr>" "diff this")
      (map "]h" "<cmd>Gitsigns next_hunk<cr>" "next hunk")
      (map "[h" "<cmd>Gitsigns prev_hunk<cr>" "previous hunk")
      {
        mode = [
          "o"
          "x"
        ];
        key = "ih";
        action.__raw = "function() require('gitsigns').select_hunk() end";
        options.desc = "select inside hunk";
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "ah";
        action.__raw = "function() require('gitsigns').select_hunk({ greedy = true }) end";
        options.desc = "select around hunk";
      }
    ];
}
