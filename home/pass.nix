{ pkgs, ... }:
{
  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  programs.password-store = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    pinentry = {
      package = pkgs.pinentry-bemenu;
    };
  };
}
