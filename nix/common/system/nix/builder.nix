{ user, ... }:
{
  users.users.${user.builderUsername} = {
    isNormalUser = true;
    createHome = false;
    home = "/var/empty";
    group = user.builderUsername;
    openssh.authorizedKeys.keys = user.keys;
    openssh.authorizedKeys.keyFiles = user.clientKeyFiles;
  };
  users.groups.${user.builderUsername} = { };
  services.openssh.settings.AllowUsers = [
    user.builderUsername
  ];
  # sign the derivations so that we can use the builder as a cache
  nix.settings.secret-key-files = "/etc/nix/cache.pem";
}
