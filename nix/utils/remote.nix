{ user, ... }:
let
  name = "remotebuild";
in
{
  users.users.${name} = {
    isNormalUser = true;
    createHome = false;
    group = name;
    openssh.authorizedKeys.keys = user.keys;
  };
  users.groups.${name} = { };
  services.openssh.settings.AllowUsers = [
    name
  ];
  # not sure if we need this
  # nix.settings.trusted-users = [ name ];
}
