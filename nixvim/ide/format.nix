{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      format_on_save = {
        lsp_format = "fallback";
        formatters_by_ft = {
          lua = "stylua";
          nix = "nixfmt";
          yaml = "yamlfmt";
          markdown = "mdformat";
          haskell = "ormolu";
          python = [
            "isort"
            "black"
          ];
        };
      };
    };
  };
}
