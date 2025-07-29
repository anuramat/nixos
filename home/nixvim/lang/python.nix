{ hax, ... }:
let
  inherit (hax.vim) luaf;
  set = key: hax.vim.set ("<localleader>" + key);
in
{
  plugins = {

    conform-nvim.settings.formatters_by_ft.python = [
      "isort"
      "black"
    ];
    lsp.servers.pyright.enable = true;

    jupytext = {
      enable = true;
      # BUG TODO jupytext doesn't get installed automatically, report
      # related but closed: <https://github.com/nix-community/nixvim/issues/2367>
      python3Dependencies = ps: with ps; [ jupytext ];
      settings = {
        force_ft = "markdown";
        output_extension = "md";
        style = "markdown";
      };
    };
  };
}
