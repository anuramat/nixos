{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  programs = {
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
    wayprompt.enable = true;
    # figure out rust version or keyring locking
    password-store = {
      enable = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    pinentry = {
      package = pkgs.wayprompt;
      program = "pinentry-wayprompt";
    };
    defaultCacheTtl = 999999;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
}
