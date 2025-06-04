{ dummy, ... }:
let
  email = "x@ctrl.sn";
in
{
  imports = dummy ./.;

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
