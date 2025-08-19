{ inputs, ... }:
{
  imports = with inputs.self.homeModules; [
    default
    heavy
    anuramat
    standalone
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
