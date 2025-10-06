{
  pkgs,
  hax,
  osConfig ? null,
  ...
}:
{
  plugins = {
    conform-nvim.settings.formatters_by_ft.nix = [
      "nixfmt"
      "injected"
    ];

    lsp.servers = {
      statix.enable = true;
      nil_ls.enable = true;

      nixd = {
        enable = false;
        cmd = [
          "nixd"
          "--inlay-hints=false"
        ];
        settings.options = {
          nixvim.expr = "(builtins.getFlake (builtins.toString ./.)).packages.${pkgs.system}.neovim.options";
        }
        // (
          if osConfig != null then
            let
              nixosExpr = ''(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${osConfig.networking.hostName}.options'';
            in
            {
              nixos.expr = nixosExpr;
              home-manager.expr = "${nixosExpr}.home-manager.users.type.getSubOptions []";
            }
          else
            throw "TODO this is only configured for nixos.home-manager.nixvim setup for now"
        );
        onAttach.function = # lua
          ''
            client.server_capabilities.renameProvider = false
          '';
      };
    };
  };
  extraFiles = hax.vim.files.injections {
    nix = # query
      ''
        ;; extends

        (apply_expression
          function: (_) @_func
          argument: [
            (string_expression
              ((string_fragment) @injection.content
                (#set! injection.language "lua")))
            (indented_string_expression
              ((string_fragment) @injection.content
                (#set! injection.language "lua")))
          ]
          (#match? @_func "(^|\\.)luaf?$"))
      '';
  };
}
