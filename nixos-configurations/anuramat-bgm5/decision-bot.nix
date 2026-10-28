{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  decision-bot = pkgs.writers.writePython3Bin "decision-bot" {
    libraries = with pkgs.python3Packages; [
      pillow
      python-telegram-bot
    ];
    # black owns line length, and breaks lines before binary operators
    flakeIgnore = [
      "E501"
      "W503"
    ];
  } ./decision-bot.py;
in
{
  systemd.services.decision-bot = {
    description = "Telegram bot replying through the decision model";
    after = [
      "decision-frontend.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe decision-bot} http://127.0.0.1:${toString inputs.self.consts.llama.decisionPort}/v1/systemone";
      LoadCredential = [
        "token:${config.age.secrets.decision-bot-token.path}"
        "config:${config.age.secrets.decision-bot-config.path}"
      ];
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
