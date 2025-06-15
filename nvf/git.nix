{ lib, ... }:
{
  vim = {
    git = {
      enable = true;
      gitlinker-nvim = {
        setupOpts = {
          opts = {
            add_current_line_on_normal_mode = false;
            print_url = true;
          };
        };
      };
      gitsigns = {
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
        mappings =
          let
            nil = lib.mkForce null;
          in
          {
            stageHunk = "<leader>gs";
            stageBuffer = "<leader>gS";
            resetHunk = "<leader>gr";
            resetBuffer = "<leader>gR";
            blameLine = "<leader>gb";
            previewHunk = "<leader>gp";
            diffThis = "<leader>gd";
            nextHunk = "]h";
            previousHunk = "[h";
            diffProject = nil;
            undoStageHunk = nil;
            toggleBlame = nil;
            toggleDeleted = nil;
          };
      };
    };
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
      in
      [
        (mkKeymap [ "o" "x" ] "ih" "function() require('gitsigns').select_hunk() end" {
          desc = "select inside hunk";
        })
        (mkKeymap [ "o" "x" ] "ah" "function() require('gitsigns').select_hunk({ greedy = true }) end" {
          desc = "select around hunk";
        })
      ];
  };
}
# vim: fdl=0
