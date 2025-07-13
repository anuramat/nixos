{ lib, ... }:
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
      map = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
      mapWrap = key: action: map "<leader>g${key}" "<cmd>Gitsigns ${action}<cr>" "${action} [Gitsigns]";
    in
    [
      (mapWrap "s" "stage_hunk")
      (mapWrap "S" "stage_buffer")
      (mapWrap "r" "reset_hunk")
      (mapWrap "R" "reset_buffer")
      (mapWrap "b" "blame_line")
      (mapWrap "p" "preview_hunk")
      (mapWrap "d" "diffthis")

      (map "]h" "<cmd>Gitsigns next_hunk<cr>" "next hunk")
      (map "[h" "<cmd>Gitsigns prev_hunk<cr>" "previous hunk")

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
