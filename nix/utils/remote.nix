{ user, ... }:
{
  users.users.remotebuild = {
    isNormalUser = true;
    createHome = false;
    group = "remotebuild";
    openssh.authorizedKeys.keys = user.keys;
  };
  users.groups.remotebuild = { };
  # not sure if we need this
  # nix.settings.trusted-users = [ "remotebuild" ];
}
