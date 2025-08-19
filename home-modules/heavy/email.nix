{ config, ... }:
let
  inherit (config.programs) git;
  email = git.userEmail;
  fullname = git.userName;
in
{
  programs.himalaya = {
    # BUG doesn't work yet with protonmail-bridge <https://github.com/pimalaya/himalaya/issues/574>
    enable = true;
    settings = {
      display-name = fullname;
      signature = "Regards,\n";
      signature-delim = "-- \n";
      downloads-dir = "~/Downloads";
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
            encryption.type = "start-tls";
            auth = {
              type = "password";
              cmd = "pass show manualBridge";
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
