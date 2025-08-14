{ user, ... }:
{
  programs.himalaya = {
    # BUG doesn't work yet with protonmail-bridge <https://github.com/pimalaya/himalaya/issues/574>
    enable = true;
    settings = {
      display-name = user.fullname;
      signature = "Regards,\n";
      signature-delim = "-- \n";
      downloads-dir = "~/Downloads";
    };
  };
  accounts.email.accounts.primary = {
    address = user.email;
    primary = true;
    realName = user.fullname;
    himalaya = {
      enable = true;
      settings =
        let
          backend = {
            login = user.email;
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
          email = user.email;
          inherit backend;
          message.send.backend = backend // {
            type = "smtp";
            port = 1025;
          };
        };
    };
  };
}
