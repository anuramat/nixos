{ inputs, ... }:
{
  imports = with inputs.self.homeModules; [
    default
    heavy
    anuramat
    standalone
    darwin
  ];
  home =
    let
      username = "anuramat";
    in
    {
      inherit username;
      # XXX CHANGE THESE TWO:
      # stateVersion = "25.05";
      # homeDirectory = "/Users/${username}";
    };
}
