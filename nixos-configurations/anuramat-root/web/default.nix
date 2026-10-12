{ inputs, ... }:
let
  inherit (inputs.self.consts.user) email;
in
{
  imports = [
    ./index.nix
    ./pastebin.nix
  ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services = {
    nginx = {
      enable = true;
      recommendedProxySettings = true;
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = { inherit email; };
  };
}
