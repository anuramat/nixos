{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) shellEscapeArg getExe;
  passDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;
in
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

  lib.keyring = rec {
    list = pkgs.writeShellApplication {
      # list all keygrips used by pass
      name = "pass-list-keygrips";
      runtimeInputs = with pkgs; [
        gnupg
        gawk
        findutils # xargs
      ];
      text = ''
        # TODO is this required? should already be set in the environment
        GNUPGHOME=${shellEscapeArg config.programs.gpg.homedir}
        export GNUPGHOME
        xargs -r gpg --list-keys --with-colons --with-keygrip < ${shellEscapeArg passDir}/.gpg-id \
        	| awk -F: '/^sub/{x=1} x&&/^grp/{print $10;x=0}'
      '';
    };
    lock = pkgs.writeShellApplication {
      # clear the gpg-agent cache for all keygrips used by pass
      name = "pass-lock";
      runtimeInputs = with pkgs; [
        gnupg
        findutils # xargs
        list
      ];
      text = ''
        # TODO is this required? should already be set in the environment
        GNUPGHOME=${shellEscapeArg config.programs.gpg.homedir}
        export GNUPGHOME
        pass-list-keygrips | xargs -I{} gpg-connect-agent "clear_passphrase --mode=normal {}" /bye
      '';
    };
  };
}
