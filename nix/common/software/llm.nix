{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    # pull models on service start
    loadModels = [ ];
  };
}
