{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) escapeShellArg getExe;
  inherit (config.programs.git.settings.user) email name;

  mailcap = pkgs.writeText "mailcap" ''
    text/html; ${getExe pkgs.html2text} -width 120 -ansi -ignore-color -osc8 %s; copiousoutput
  '';

  neomuttDesktop = pkgs.writeTextFile {
    name = "neomutt.desktop";
    destination = "/share/applications/neomutt.desktop";
    text = ''
      [Desktop Entry]
      Type=Application
      Name=neomutt
      Exec=neomutt %u
      Terminal=true
      MimeType=x-scheme-handler/mailto;
    '';
  };
in
{
  home = {
    packages = with pkgs; [
      protonmail-bridge
      neomuttDesktop
    ];
    activation = {
      # BUG doesn't get created on first run, report/contribute
      neomuttCache =
        let
          path = "${config.xdg.cacheHome}/neomutt/messages";
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p ${escapeShellArg path}
        '';
    };
  };
  programs = {
    neomutt = {
      enable = true;
      vimKeys = true;
      sort = "reverse-date";
      binds = [
        {
          key = "R";
          action = "imap-fetch-mail";
          map = [ "index" ];
        }
      ];
      extraConfig = ''
        auto_view text/html
        set implicit_autoview
        set mailcap_path=${mailcap}
        set allow_ansi = yes
        alternative_order text/plain text/html
        set pager = "less -r -S"
        unset prompt_after

        set trash = "+Trash"
        set certificate_file="${config.xdg.cacheHome}/neomutt/certificates"
        set to_chars="       "
        set index_format="%zt %4C %[%y-%m-%d] %-15.15L %s %> %a"
        source ${inputs.base16-mutt}/base16.muttrc
      '';
    };
  };

  systemd.user.services.protonmail-bridge =
    let
      target = config.wayland.systemd.target;
    in
    {
      # NOTE to log in: `protonmail-bridge --cli`
      Unit = {
        Description = "ProtonMail Bridge";
        After = [ target ];
      };
      Install.WantedBy = [ target ];
      Service = {
        ExecStart = "${getExe pkgs.protonmail-bridge} --noninteractive";
        Restart = "always";
        RestartSec = 10;
      };
    };

  accounts.email = {
    accounts.primary = {
      primary = true;
      userName = email;
      address = email;
      realName = name;

      imap = {
        host = "127.0.0.1";
        port = 1143;
        tls.enable = false;
      };
      smtp = {
        host = "127.0.0.1";
        port = 1025;
        tls.enable = false;
      };

      passwordCommand =
        let
          secret-tool = lib.getExe pkgs.libsecret;
          server = "protonmail/bridge-v3/users/${email}/imap-password";
        in
        "${secret-tool} lookup server ${server}";

      neomutt = {
        enable = true;
        mailboxType = "imap";
        extraConfig = ''
          set imap_check_subscribed
        '';
      };
      imapnotify = {
        enable = true;
        boxes = [ "INBOX" ];
        onNotify =
          let
            term_cmd = "${config.home.sessionVariables.TERMCMD}";
          in
          ''
            [ "$(${getExe pkgs.libnotify} "New email" -a mail -A default=Open -e)" = default ] && ${term_cmd} -e neomutt
          '';
      };
    };
  };

  services.imapnotify = {
    enable = true;
    path = [
      pkgs.libnotify
      # TODO not sure if these are needed:
      pkgs.gnupg
      pkgs.pinentry-tty
    ];
  };

  systemd.user.services.imapnotify =
    let
      targets = [
        "gpg-agent.service"
        "protonmail-bridge.service"
      ];
    in
    {
      Unit = {
        After = targets;
        Wants = targets;
      };
      Service.Environment = [
        "PASSWORD_STORE_DIR=${config.programs.password-store.settings.PASSWORD_STORE_DIR}"
      ];
    };
}
