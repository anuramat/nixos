{
  config,
  lib,
  ...
}:
let
  cuda = config.hardware.nvidia.enabled;
in
{
  services = {
    litellm = {
      enable = false;
      port = 15151;
      environmentFile = config.age.secrets.litellm.path;
      openFirewall = false;
      settings = {
        model_list = [
          {
            model_name = "github_copilot/gpt-4";
            litellm_params = {
              model = "github_copilot/gpt-4";
            };
          }
        ];
      };
    };
    ollama = {
      enable = true;
      acceleration = lib.mkIf cuda "cuda";
      loadModels = lib.mkIf cuda [ ]; # pull models on service start
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
      };
      port = 11434; # explicit default
      host = "0.0.0.0";
      # openFirewall = false; # disable to limit the interfaces
    };
    # # WARN not in the binary cache yet, takes years to compile
    # open-webui = {
    #   host = "0.0.0.0";
    #   enable = true;
    #   port = 12345;
    #   package = open-webui;
    #   # openFirewall = false; # disable to limit the interfaces
    # };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.services.ollama.port
  ];
}
