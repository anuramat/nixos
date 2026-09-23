{ pkgs, ... }:
{
  virtualisation = {
    containers.enable = true; # common container config files in /etc/containers
    podman = {
      enable = true;
      dockerCompat = true;
      # > Required for containers under podman-compose to be able to talk to each other.
      # TODO is this still needed?
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    ctop # top for containers
    distrobox
    dive # look into docker image layers
    podman-compose
    podman-tui # podman container status
  ];
}
