{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./files.nix
    ./fzf.nix
    ./git.nix
    ./ide.nix
    ./markdown.nix
    ./misc.nix
    ./treesitter.nix
    ./ui.nix
    ./vimim.nix
    ./llm.nix
  ];

  package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;

  # TODO lazy
  # TODO lualoader

  viAlias = false;
  vimAlias = false;

  extraConfigLuaPre = ''
    vim.cmd('source ${./base.vim}')
    vim.diagnostic.config({
      severity_sort = true,
      update_in_insert = true,
      signs = false,
    })
    vim.deprecate = function() end
  '';

  plugins = {
    web-devicons.enable = true;
    lsp = {
      enable = true;
      inlayHints = false;
      servers = {
        clangd.enable = true;
        html.enable = true;
        lua_ls.enable = true;
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
          cmd = "{ 'vscode-json-languageserver', '--stdio' }";
          # schemas = "require('schemastore').json.schemas()"; # TODO
        };
        lua_ls = {
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
        nixd = {
          enable = true;
          cmd = [
            "nixd"
            "--inlay-hints=false"
          ];
          settings = {
            nixd = {
              options =
                let
                  hostname = "";
                  root = ''(builtins.getFlake "/etc/nixos/")'';
                  nixosExpr = ''${root}.nixosConfigurations.${hostname}.options'';
                  homeExpr = "${nixosExpr}.home-manager.users.type.getSubOptions []";
                  vimExpr = "${root}.packages.${pkgs.system}.neovim.options";
                in
                {
                  nixos = {
                    expr = nixosExpr;
                  };
                  home-manager = {
                    expr = homeExpr;
                  };
                  nixvim = {
                    expr = vimExpr;
                  };
                };
            };
          };
        };
        stylelint_lsp = {
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

  };
}
