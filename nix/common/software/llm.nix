{ pkgs, ... }:
{
  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = true;
    # pull models on service start
    loadModels = [ ];
  };
}
