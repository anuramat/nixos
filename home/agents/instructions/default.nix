{ config, lib, ... }:
let
  topHead = "#";
  sectionHead = "${topHead}#";
  head = "${sectionHead}#";

  prependTitle = body: lib.concatStringsSep "\n" ([ "${topHead} Global instructions\n" ] ++ body);
  mkInstructions =
    parts: parts |> lib.mapAttrsToList (n: v: "${sectionHead} ${n}\n\n" + v) |> prependTitle;
  inherit (lib.agents) mainContextFile;

  text = mkInstructions config.lib.agents.instructions.parts;
in
{
  imports = [
    ./codestyle.nix
    ./general.nix
    ./git.nix
    ./markdown.nix
    ./workflow.nix
  ];
  lib.agents.instructions = {
    inherit
      head
      mkInstructions
      text
      ;
    path = "${config.home.homeDirectory}/${config.xdg.configFile.${mainContextFile}.target}";
  };
  xdg.configFile.${mainContextFile} = { inherit text; };
}
