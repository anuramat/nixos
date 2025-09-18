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
in
{
  home.packages = with pkgs; [ protonmail-bridge ];

  programs = {
    neomutt.enable = true;
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
      };
      # TODO first start will ask for cert acceptance; can we automate that?
      # NOTE to enable cache:
      # mkdir -p ${config.xdg.cacheHome}/neomutt/messages/
    };
  };

}
