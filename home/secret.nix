{ config, pkgs, ... }:
{
  services.pass-secret-service-rs.enable = true; # secret service api -- exposes password-store over dbus
  # WARN locking only marks keyring as locked, secrets are still accessible
  programs = {
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
    # TODO trans to rust ver
    password-store = {
      enable = true;
      # uses gpg-agent to encrypt/decrypt secrets
    };
  };
  home = {
    packages = with pkgs; [
      pinentry-tty # just in case
    ];
  };
  services.gpg-agent = {
    enable = true;
    pinentry = {
      package = pkgs.pinentry-bemenu;
    };
    defaultCacheTtl = 999999;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
}
