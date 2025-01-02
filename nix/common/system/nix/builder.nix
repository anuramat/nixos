{ user, ... }:
{
  # remote build part {{{1
  nix.distributedBuilds = false;
  users.users.${user.builderUsername} = {
    isNormalUser = true;
    createHome = false;
    group = user.builderUsername;
    openssh.authorizedKeys.keys = user.keys;
  };
  users.groups.${user.builderUsername} = { };
  services.openssh.settings.AllowUsers = [
    user.builderUsername
  ];
  # TODO not sure if we need this, research
  # nix.settings.trusted-users = [ name ];

  # binary cache part {{{1
  services = {
    nix-serve = {
      enable = true;
      secretKeyFile = "/var/cache.pem";
    };
  };
  networking.firewall.allowedTCPPorts = [
    5000
  ];
}
