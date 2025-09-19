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
    text/html; ${lib.getExe pkgs.html2text} -links %s; copiousoutput
  '';
in
{
  home.packages = with pkgs; [ protonmail-bridge ];

  programs = {
    neomutt = {
      enable = true;
      vimKeys = true;
      # sidebar.enable = true;
      sort = "date";
      # TODO explain these
      extraConfig = ''
        auto_view text/html
        set implicit_autoview
        set mailcap_path=${mailcap}
        alternative_order text/plain text/html
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
      };
      imapnotify = {
        enable = true;
        boxes = [ "INBOX" ];
        onNotify = ''${lib.getExe pkgs.libnotify} -a mail "New email"'';
      };
      # TODO first start will ask for cert acceptance; can we automate that?
      # NOTE to enable cache:
      # TODO BUG REPORT, it's not created by default
      # mkdir -p ${config.xdg.cacheHome}/neomutt/messages/
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
