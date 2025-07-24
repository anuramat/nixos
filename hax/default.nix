args: {
  agents = import ./agents args;
  common = import ./common.nix args;
  web = import ./web.nix args;
  mime = import ./mime.nix args;
  hosts = import ./hosts.nix args;
  vim = import ./vim.nix args;
  home = import ./home.nix args;
}
