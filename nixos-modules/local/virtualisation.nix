{ config, ... }:
{
  # TODO check through virtualisation; also maybe we can move some of it
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
  hardware.nvidia-container-toolkit = {
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true;
  };
}
