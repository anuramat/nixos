{ lib, pkgs, ... }:
{
  plugins = {
    treesitter = {
      enable = true;
      grammarPackages =
        pkgs.vimPlugins.nvim-treesitter.builtGrammars
        |> lib.filterAttrs (n: v: lib.strings.hasPrefix "tree-sitter" n)
        |> builtins.attrValues;

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

    treesitter-textobjects.enable = true;
  };
}
