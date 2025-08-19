{ ezModules, ... }:
{
  imports = [
    ezModules.standalone
    ezModules.anuramat
  ];
  home =
    let
      username = "anuramat";
    in
    {
      inherit username;
      # XXX CHANGE THESE TWO:
      stateVersion = "24.11";
      homeDirectory = "/home/${username}";
    };
}
