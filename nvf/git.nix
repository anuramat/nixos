{ lib, ... }:
{
  config.vim = {
    git = {
      gitlinker-nvim = {
        enable = true;
        setupOpts = {
          opts = {
            add_current_line_on_normal_mode = false;
            print_url = true;
          };
        };
      };
      gitsigns = {
        enable = true;
        setupOpts = {
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
        mappings = lib.mkForce {
          # XXX doesn't work
          stageHunk = "<leader>gs";
          stageBuffer = "<leader>gS";
          resetHunk = "<leader>gr";
          resetBuffer = "<leader>gR";
          blameLine = "<leader>gb";
          previewHunk = "<leader>gp";
          diffThis = "<leader>gd";
          nextHunk = "]h";
          previousHunk = "[h";
        };
      };
      vim-fugitive.enable = true;
    };
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
      in
      [
        (mkKeymap "ih" [ "o" "x" ] "function() require('gitsigns').select_hunk() end" {
          desc = "select inside hunk";
        })
        (mkKeymap "ah" [ "o" "x" ] "function() require('gitsigns').select_hunk({ greedy = true }) end" {
          desc = "select around hunk";
        })
      ];
  };
}
