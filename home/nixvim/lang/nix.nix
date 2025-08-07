{ pkgs, hax, ... }:
{
  plugins = {
    conform-nvim.settings.formatters_by_ft.nix = [
      "nixfmt"
      "injected"
    ];

    lsp.servers = {
      statix = { }; # enable when they have pipes: <https://github.com/oppiliappan/statix/issues/88>

      nil_ls = {
        enable = true;
      };

      nixd = {
        enable = true;
        cmd = [
          "nixd"
          "--inlay-hints=false"
        ];
        settings = {
          options.nixvim.expr = "(builtins.getFlake (builtins.toString ./.)).packages.${pkgs.system}.neovim.options";
        };
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
