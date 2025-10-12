{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) escapeShellArg getExe;
  passDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;
  pamGnupgPath = "${config.xdg.configHome}/pam-gnupg";
  gpgIdPath = "${passDir}/.gpg-id";
  gnupgHome = config.programs.gpg.homedir;

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
      GNUPGHOME=${escapeShellArg config.programs.gpg.homedir}
      export GNUPGHOME
      xargs -r gpg --list-keys --with-colons --with-keygrip < ${escapeShellArg gpgIdPath} \
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
      GNUPGHOME=${escapeShellArg config.programs.gpg.homedir}
      export GNUPGHOME
      pass-list-keygrips | xargs -I{} gpg-connect-agent "clear_passphrase --mode=normal {}" /bye
    '';
  };

  generatePamGnupg = pkgs.writeShellApplication {
    name = "pass-generate-pam-gnupg";
    runtimeInputs = with pkgs; [
      coreutils # mkdir, cat
      findutils # xargs
      list
    ];
    text = ''
      target=${escapeShellArg pamGnupgPath}
      echo ${escapeShellArg gnupgHome} > "$target"
      pass-list-keygrips >> "$target"
    '';
  };
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

  lib.keyring = {
    inherit
      list
      lock
      generatePamGnupg
      ;
  };

  # TODO vet

  systemd.user.services.pass-pam-gnupg-watcher = {
    Unit = {
      Description = "Regenerate pam-gnupg on .gpg-id changes";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${getExe config.lib.keyring.generatePamGnupg}";
    };
  };

  systemd.user.paths.pass-pam-gnupg-watcher = {
    Unit = {
      Description = "Watch .gpg-id for changes";
      PartOf = [ "graphical-session.target" ];
    };
    Path = {
      PathModified = gpgIdPath;
      Unit = "pass-pam-gnupg-watcher.service";
    };
    Install = {
      WantedBy = [ "paths.target" ];
    };
  };
}
