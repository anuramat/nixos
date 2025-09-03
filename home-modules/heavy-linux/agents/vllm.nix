{
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # vllm
  ];

  # systemd.user.services.vllm = {
  #   Unit = {
  #     Description = "vLLM OpenAI API Server";
  #     After = [ "graphical-session.target" ];
  #   };
  #
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  #
  #   Service = {
  #     Type = "exec";
  #     Restart = "never";
  #     # Restart = "on-failure";
  #     # RestartSec = "5s";
  #
  #     ExecStart =
  #       let
  #         vllm = lib.getExe pkgs.vllm;
  #       in
  #       # bash
  #       "${vllm} serve microsoft/DialoGPT-medium --host 0.0.0.0 --port 11444 --gpu-memory-utilization 0.8";
  #   };
  # };
}
