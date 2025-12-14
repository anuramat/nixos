{
  hax,
  lib,
  config,
  pkgs,
  ...
}:
let
  snippets = hax.vim.files {
    toml = {
      snippets =
        let
          fmt = x: x |> lib.trim |> lib.splitString "\n";
        in
        lib.mapAttrs'
          (
            n: v:
            lib.nameValuePair n {
              body = fmt v;
              prefix = n;
            }
          )
          {
            go = ''
              [formatter.gofmt]
              command = "gofmt"
              options = [ "-w" ]
              includes = [ "*.go" ]

              [formatter.gofumpt]
              command = "gofumpt"
              options = [ "-w" ]
              includes = [ "*.go" ]

              [formatter.goimports]
              command = "goimports"
              options = [ "-w" ]
              includes = [ "*.go" ]
            '';
            nix = ''
              # [formatter.nix]
              # command = "nixfmt"
              # includes = [ "*.nix" ]
            '';
            lua = ''
              [formatter.lua]
              command = "stylua"
              includes = [ "*.lua" ]
            '';
            sh = ''
              [formatter.shfmt]
              includes = [ "*.sh" ]
              command = "shfmt"
              options = [ "--write", "--simplify", "--case-indent", "--binary-next-line" ]

              [formatter.shellharden]
              includes = [ "*.sh" ]
              command = "shellharden"
              options = [ "--replace" ]
            '';
            yaml = ''
              [formatter.yaml]
              includes = [ "*.yaml" ]
              command = "yamlfmt"
            '';
            python = ''
              [formatter.python]
              command = "black"
              includes = [ "*.py" ]
              options = [ "-q" ]
            '';
          };
    };
  };
in
{
  extraPackages = with pkgs; [
    hadolint
  ];
  plugins = {
    lint.lintersByFt = {
      dockerfile = [
        "hadolint"
      ];
    };

    lsp.servers = {
      clangd.enable = true;
      zls.enable = true;
      ast_grep = {
        enable = true;
        filetypes = [ "typst" ];
      };
    };
  };

  files = hax.vim.files {
    vim = {
      ftp = {
        fo = config.opts.formatoptions; # TODO why do we do this again? see lua.nix
      };
    };
  };

  filetype = {
    filename = {
      "todo.txt" = "todotxt";
    };
  };

  extraFiles = snippets;
}
