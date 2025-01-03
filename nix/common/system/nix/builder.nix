{ machines, user, ... }:
{
  users.users.${machines.builderUsername} = {
    isNormalUser = true;
    createHome = false;
    home = "/var/empty";
    group = machines.builderUsername;
    openssh.authorizedKeys.keys = user.keys;
    openssh.authorizedKeys.keyFiles = machines.clientKeyFiles;
  };
  users.groups.${machines.builderUsername} = { };
  services.openssh.settings.AllowUsers = [
    machines.builderUsername
  ];
  # sign the derivations so that we can use the builder as a cache
  nix.settings.secret-key-files = "/etc/nix/cache.pem";
}
