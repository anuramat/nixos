{ pkgs, ... }:
{
  keymaps =
    let
      _mkMap = key: action: desc: {
        mode = "n";
        inherit key action desc;
      };
      mkMap =
        k: a: d:
        _mkMap ("gr" + k) { __raw = a; } d;
    in
    [
      (mkMap "d" "vim.lsp.buf.declaration" "Goto Declaration")
      (mkMap "t" "vim.lsp.buf.type_definition" "Goto Type Definition")
      (mkMap "q" "vim.diagnostic.setqflist" "Diagnostic QF List")
      (mkMap "l" "vim.lsp.codelens.run" "CodeLens")
    ];
  plugins.lsp = {
    enable = true;
    inlayHints = false;
    servers = {
      clangd.enable = true;
      html.enable = true;
      nil_ls.enable = true;
      pyright.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      ts_ls.enable = true;
      zls.enable = true;
      bashls = {
        enable = true;
        settings = {
          bashIde = {
            shfmt = {
              binaryNextLine = true;
              caseIndent = true;
              simplifyCode = true;
              spaceRedirects = true;
            };
          };
        };
      };
      gopls = {
        enable = true;
        settings = {
          gopls = {
            analyses = {
              shadow = true;
              unusedvariable = true;
              unusedwrite = true;
              useany = true;
            };
            codelenses = {
              gc_details = true;
              generate = true;
              regenerate_cgo = true;
              tidy = true;
              upgrade_dependency = true;
              vendor = true;
            };
            gofumpt = true;
            hints = {
              assignVariableTypes = false;
              compositeLiteralFields = false;
              compositeLiteralTypes = false;
              constantValues = false;
              functionTypeParameters = false;
              parameterNames = false;
              rangeVariableTypes = false;
            };
            semanticTokens = true;
            staticcheck = true;
            usePlaceholders = true;
          };
        };
      };
      jsonls = {
        enable = false; # TODO fix
        cmd = [
          "vscode-json-languageserver"
          "--stdio"
        ];
      };
      lua_ls = {
        enable = true;
        settings = {
          Lua = {
            format = {
              enable = false;
            };
            runtime = {
              version = "LuaJIT";
            };
            telemetry = {
              enable = false;
            };
          };
        };
      };
      marksman.enable = true;
      statix = { }; # enable when they have pipes: <https://github.com/oppiliappan/statix/issues/88>
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
      stylelint_lsp = {
        # css
        enable = true;
      };
      superhtml.enable = true;
      texlab = {
        settings = {
          texlab = {
            build = {
              forwardSearchAfter = true;
              onSave = true;
            };
            chktex = {
              onEdit = true;
              onOpenAndSave = true;
            };
            forwardSearch = {
              args = [
                "--synctex-forward"
                "%l:1:%f"
                "%p"
              ];
              executable = "zathura";
            };
          };
        };
      };
      yamlls.enable = true;
    };
  };
}
