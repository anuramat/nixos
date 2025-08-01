{
  cluster,
  config,
  lib,
  ...
}:
lib.mkIf (!config.nix.distributedBuilds) {
  users.users.${cluster.builderUsername} = {
    isNormalUser = true; # TODO maybe not?
    createHome = false;
    home = "/var/empty";
    group = cluster.builderUsername;
    openssh.authorizedKeys.keyFiles = cluster.clientKeyFiles;
  };
  users.groups.${cluster.builderUsername} = { };
  services.openssh.settings.AllowUsers = [
    cluster.builderUsername
  ];
}
