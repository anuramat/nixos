{ lib, pkgs, ... }:
{
  plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        incremental_selection = {
          enable = true;
          keymaps = {
            node_decremental = "<bs>";
            node_incremental = "<c-space>";
          };
        };
      };
    };

    treesitter-textobjects.enable = true;

    ts-comments.enable = true;

    treesitter-context = {
      enable = true;
      settings = {
        enable = true;
        max_lines = 1;
        min_window_height = 20;
        line_numbers = true;
        multiline_threshold = 1;
        trim_scope = "outer";
        mode = "cursor";
      };
    };

    treesj = {
      enable = true;
      lazyLoad = {
        enable = true;
        settings = {
          keys = [
            {
              __unkeyed-1 = "<leader>j";
              __unkeyed-2.__raw = ''function() require('treesj').toggle() end'';
              desc = "TreeSJ: Split/Join a Treesitter node";
            }
          ];
        };
      };
    };
  };
}
