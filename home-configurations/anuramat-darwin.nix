{ inputs, ... }:
let
  inherit (inputs.self.user) username;
in
{
  imports = with inputs.self.homeModules; [
    standalone
    darwin
    base
    local
    heavy
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.11";
  };
}
