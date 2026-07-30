{ inputs, ... }:
let
  inherit (inputs.self.user) username;
in
{
  imports = with inputs.self.homeModules; [
    standalone
    darwin
    default
    heavy
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.11";
  };
}
