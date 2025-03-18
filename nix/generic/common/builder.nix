{
  cluster,
  config,
  lib,
  ...
}:
lib.mkIf (!config.nix.distributedBuilds) {
  users.users.${cluster.builderUsername} = {
    isNormalUser = true;
    createHome = false;
    home = "/var/empty";
    group = cluster.builderUsername;
    openssh.authorizedKeys.keyFiles = cluster.clientKeyFiles;
  };
  users.groups.${cluster.builderUsername} = { };
  services.openssh.settings.AllowUsers = [
    cluster.builderUsername
  ];
  # sign the derivations so that we can use the builder as a cache
  nix.settings.secret-key-files = "/etc/nix/cache.pem";
  # NOTE might wanna add gc and autoUpgrade later
}
