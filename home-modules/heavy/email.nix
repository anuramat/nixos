{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.programs) git;
  email = git.userEmail;
  fullname = git.userName;
  mailcap = pkgs.writeText "mailcap" ''
    text/html; ${lib.getExe pkgs.html2text} -width 120 -ansi -ignore-color -osc8 %s; copiousoutput
  '';
in
{
  home = {
    packages = with pkgs; [ protonmail-bridge ];
    activation = {
      neomuttCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${config.xdg.cacheHome}/neomutt/messages
      '';
      # TODO robustify string
      # TODO BUG REPORT, it's not created by default
    };
  };
  programs = {
    neomutt = {
      enable = true;
      vimKeys = true;
      # sidebar.enable = true;
      sort = "reverse-date";
      # TODO explain these
      extraConfig = ''
        set certificate_file="${config.xdg.cacheHome}/neomutt/certificates"
        auto_view text/html
        set implicit_autoview
        set mailcap_path=${mailcap}
        set allow_ansi = yes
        alternative_order text/plain text/html

        set pager = "less -r -S"
        unset prompt_after
      '';
    };
  };

  systemd.user.services.protonmail-bridge = {
    # NOTE to log in:
    # protonmail-bridge --cli
    Unit = {
      Description = "ProtonMail Bridge";
      After = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${lib.getExe pkgs.protonmail-bridge} --noninteractive";
      Restart = "always";
      RestartSec = 10;
    };
  };

  accounts.email = {
    accounts.primary = {
      primary = true;

      userName = email;
      address = email;
      realName = fullname;
      passwordCommand =
        let
          pass = lib.getExe pkgs.pass;
        in
        "${pass} show proton-bridge/${email}";
      # passwordCommand =
      #   let
      #     secret-tool = lib.getExe pkgs.libsecret;
      #     server = "protonmail/bridge-v3/users/bridge-vault-key";
      #     username = "bridge-vault-key";
      #   in
      #   "${secret-tool} lookup server ${server} username ${username}";

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

      neomutt = {
        enable = true;
        mailboxType = "imap";
        extraConfig = ''
          set imap_check_subscribed
        '';
        # TODO first start will ask for cert acceptance; can we automate that?
      };
      imapnotify = {
        enable = true;
        boxes = [ "INBOX" ];
        onNotify = ''${lib.getExe pkgs.libnotify} -a mail "New email"'';
      };
    };
  };

  services.imapnotify = {
    enable = true;
    path = [
      pkgs.libnotify
      pkgs.gnupg
      pkgs.pinentry
    ];
  };

  systemd.user.services.imapnotify = {
    Unit = {
      After = [
        "gpg-agent.service"
        "protonmail-bridge.service"
      ];
      Wants = [
        "gpg-agent.service"
        "protonmail-bridge.service"
      ];
    };
    Service = {
      Environment =
        let
          dir = config.programs.password-store.settings.PASSWORD_STORE_DIR;
        in
        [
          "PASSWORD_STORE_DIR=${dir}"
        ];
    };
  };

}
