{ ezModules, ... }:
{
  imports = [
    ezModules.standalone
  ];
  home =
    let
      username = "anuramat";
    in
    {
      # XXX CHANGE ME
      stateVersion = "24.11";

      inherit username;
      homeDirectory = "/home/${username}";
    };
}
