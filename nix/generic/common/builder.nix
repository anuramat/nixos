{
  cluster,
  config,
  lib,
  ...
}:
lib.mkIf (!config.nix.distributedBuilds) {
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    5000 # nix-serve
  ];
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
  # sign the derivations so that we can use the builder as a cache
  nix.settings.secret-key-files = "/etc/nix/cache.pem";
  # NOTE might wanna add gc and autoUpgrade later
}
