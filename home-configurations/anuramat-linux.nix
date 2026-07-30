{ inputs, ... }:
let
  inherit (inputs.self.user) username;
in
{
  imports = with inputs.self.homeModules; [
    standalone
    default
    linux
    heavy
    heavy-linux
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };
}
