{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ctop # top for containers
    dive # look into docker image layers
    kubectl
    kubectx
    podman-compose
    podman-tui # podman container status
  ];
}
