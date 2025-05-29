{
  config,
  lib,
  unstable,
  old,
  ...
}:
{
  services = {
    ollama = {
      package = unstable.ollama;
      enable = true;
      acceleration = lib.mkIf config.hardware.nvidia.enabled "cuda";
      # pull models on service start
      loadModels = [ ];
      port = 11434; # explicit default
      host = "0.0.0.0";
      # openFirewall = false; # disable to limit the interfaces
    };
    # # this fucking shit is not in the cache
    # open-webui = {
    #   host = "0.0.0.0";
    #   enable = true;
    #   port = 12345;
    #   package = old.open-webui;
    #   # openFirewall = false; # disable to limit the interfaces
    # };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.services.ollama.port
  ];
}
