{
  config,
  lib,
  ...
}:
{
  home.activation.linkGpgHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sfn "$GNUPGHOME" "$HOME/.gnupg"
  '';

  programs = {
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };
    password-store = {
      enable = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 999999;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
}
