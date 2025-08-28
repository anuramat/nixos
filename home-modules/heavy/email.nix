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
  programs.himalaya = {
    enable = true;
    settings = {
      display-name = fullname;
      signature = "Regards,\n";
      signature-delim = "-- \n";
      downloads-dir = "~/Downloads";
    };
  };
  home.packages = with pkgs; [ hydroxide ];

  systemd.user.services.hydroxide = {
    # NOTE needs manual auth: `hydroxide auth`, then save to `pass hydroxide`
    Unit = {
      Description = "Hydroxide ProtonMail Bridge";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.hydroxide} serve";
      Restart = "always";
      RestartSec = 10;
    };
  };
  accounts.email.accounts.primary = {
    address = email;
    primary = true;
    realName = fullname;
    himalaya = {
      enable = true;
      settings =
        let
          backend = {
            login = email;
            type = "imap";
            host = "127.0.0.1";
            port = 1143;
            encryption.type = "none";
            auth = {
              type = "password";
              cmd = "pass show hydroxide";
            };
          };
        in
        {
          email = email;
          inherit backend;
          message.send.backend = backend // {
            type = "smtp";
            port = 1025;
          };
        };
    };
  };
}
