{ user, ... }:
{
  home = {
    # stateVersion = "24.05"; # TODO return
    username = user.username;
    homeDirectory = "/home/${user.username}";
  };
}
