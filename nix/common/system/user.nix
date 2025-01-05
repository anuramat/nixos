{
  lib,
  ...
}:
{
  options = with lib; {
    me = mkOption {
      readOnly = true;
      type = with types; uniq str;
    };
  };
  config = rec {
    me = "anuramat";
    time.timeZone = "Europe/Berlin";
    i18n.defaultLocale = "en_US.UTF-8";
    users.users.${me} = {
      description = "Arsen Nuramatov";
    };
  };
}
