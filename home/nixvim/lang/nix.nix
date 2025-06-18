{
  plugins = {
    conform-nvim.settings.formatters_by_ft.nix = "nixfmt";

    plugins.lsp.servers = {
      nil_ls.enable = true;

      nixd = {
        enable = true;
        cmd = [
          "nixd"
          "--inlay-hints=false"
        ];
        settings = {
          options.nixvim.expr = "(builtins.getFlake (builtins.toString ./.)).packages.${pkgs.system}.neovim.options";
        };
      };
    };
  };
}
