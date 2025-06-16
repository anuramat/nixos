{ lib, pkgs, ... }:
{
  vim = {
    treesitter = {
      grammars =
        pkgs.vimPlugins.nvim-treesitter.builtGrammars
        |> lib.filterAttrs (n: v: lib.strings.hasPrefix "tree-sitter" n)
        |> builtins.attrValues;
      mappings.incrementalSelection = {
        decrementByNode = "<bs>";
        incrementByNode = "<c-space>";
        incrementByScope = lib.mkForce null;
        init = lib.mkForce null;
      };
      context = {
        enable = true;
        setupOpts = {
          enable = true;
          max_lines = 1;
          min_window_height = 20;
          line_numbers = true;
          multiline_threshold = 1;
          trim_scope = "outer";
          mode = "cursor";
        };
      };
      textobjects.enable = true;
    };
  };
}
