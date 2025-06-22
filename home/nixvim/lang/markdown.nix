{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    vale
  ];
  plugins = {
    lsp.servers.marksman.enable = true;
    lint.linters.lintersByFt.markdown = [
      "vale"
      # TODO more?
    ];
    conform-nvim.settings = {
      formatters_by_ft.markdown = [ "mdformat" ];
      formatters = {
        mdformat = {
          "inherit" = true;
          prepend_args = [ "--number" ];
        };
      };
    };
  };
}
