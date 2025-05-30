{
  config,
  lib,
  unstable,
  ...
}:
let
  cuda = config.hardware.nvidia.enabled;
  ollamaPackage = unstable.ollama.overrideAttrs (oldAttrs: rec {
    version = "0.9.0-rc0";
    src = unstable.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      rev = "v${version}";
      sha256 = "sha256-+8UHE9M2JWUARuuIRdKwNkn1hoxtuitVH7do5V5uEg0=";
    };
  });
in
{
  services = {
    ollama = {
      package = ollamaPackage;
      enable = true;
      acceleration = lib.mkIf cuda "cuda";
      loadModels = lib.mkIf cuda [ ]; # pull models on service start
      port = 11434; # explicit default
      host = "0.0.0.0";
      # openFirewall = false; # disable to limit the interfaces
    };
    # # WARN not in the binary cache yet, takes years to compile
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
