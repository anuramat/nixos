{ pkgs, ... }:
{
  # extraPackages = with pkgs; [
  # ];
  plugins = {
    lsp.servers.jsonls.enable = true;
    # lint.lintersByFt.json = [
    #   "jsonlint" # TODO dropped from nixpkgs; find replacement
    # ];
  };
}
