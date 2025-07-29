{
  hax,
  config,
  pkgs,
  ...
}:
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
    };
  };

  files = hax.vim.files.ftp {
    vim = {
      fo = config.opts.formatoptions;
    };
  };

  filetype = {
    filename = {
      "todo.txt" = "todotxt";
    };
  };
}
