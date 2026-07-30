{ inputs, ... }:
let
  inherit (inputs.self.user) email;
in
{
  imports = [
    ./index.nix
    ./pastebin.nix
  ];

  # TODO: if this works, unboilerplate with a function
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
