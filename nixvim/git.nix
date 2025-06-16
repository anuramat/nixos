{ lib, ... }:
{
  plugins = {
    gitsigns = {
      enable = true;
      settings = {
        sign_priority = 1000;
        signs_staged = {
          add = { text = "▎"; };
          change = { text = "▎"; };
          delete = { text = "▎"; };
          topdelete = { text = "▎"; };
          changedelete = { text = "▎"; };
          untracked = { text = "▎"; };
        };
      };
    };
  };
  
  keymaps = [
    { mode = "n"; key = "<leader>gs"; action = "<cmd>Gitsigns stage_hunk<cr>"; options.desc = "stage hunk"; }
    { mode = "n"; key = "<leader>gS"; action = "<cmd>Gitsigns stage_buffer<cr>"; options.desc = "stage buffer"; }
    { mode = "n"; key = "<leader>gr"; action = "<cmd>Gitsigns reset_hunk<cr>"; options.desc = "reset hunk"; }
    { mode = "n"; key = "<leader>gR"; action = "<cmd>Gitsigns reset_buffer<cr>"; options.desc = "reset buffer"; }
    { mode = "n"; key = "<leader>gb"; action = "<cmd>Gitsigns blame_line<cr>"; options.desc = "blame line"; }
    { mode = "n"; key = "<leader>gp"; action = "<cmd>Gitsigns preview_hunk<cr>"; options.desc = "preview hunk"; }
    { mode = "n"; key = "<leader>gd"; action = "<cmd>Gitsigns diffthis<cr>"; options.desc = "diff this"; }
    { mode = "n"; key = "]h"; action = "<cmd>Gitsigns next_hunk<cr>"; options.desc = "next hunk"; }
    { mode = "n"; key = "[h"; action = "<cmd>Gitsigns prev_hunk<cr>"; options.desc = "previous hunk"; }
    
    {
      mode = ["o" "x"];
      key = "ih";
      action.__raw = "function() require('gitsigns').select_hunk() end";
      options.desc = "select inside hunk";
    }
    {
      mode = ["o" "x"];
      key = "ah";
      action.__raw = "function() require('gitsigns').select_hunk({ greedy = true }) end";
      options.desc = "select around hunk";
    }
  ];
}