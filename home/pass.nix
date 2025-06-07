{ pkgs, ... }:
{
  services.pass-secret-service.enable = true; # secret service api -- exposes password-store over dbus
  # WARN locking only marks keyring as locked, secrets are still accessible
  programs.password-store = {
    enable = true;
    # uses gpg-agent to encrypt/decrypt secrets
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
