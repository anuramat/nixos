{ user, ... }:
let
  name = "builder";
in
{
  # remote build part {{{1
  users.users.${name} = {
    isNormalUser = true;
    createHome = false;
    group = name;
    openssh.authorizedKeys.keys = user.keys;
  };
  users.groups.${name} = { };
  services.openssh.settings.AllowUsers = [
    name
  ];
  # not sure if we need this
  # nix.settings.trusted-users = [ name ];

  # binary cache part {{{1
  services = {
    nix-serve = {
      enable = true;
      secretKeyFile = "/var/cache.pem";
    };
  };
  networking.firewall.allowedTCPPorts = [
    5000 # nix-serve
  ];
}
