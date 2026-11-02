{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs
    ;
in

{

  imports = [
    ./decide.nix
    ./feedback.nix
    ./frontends
    ./hostrun
    ./instructions.nix
    ./job.nix
    ./notify.nix
    ./relay
    ./sandbox.nix
    ./skills.nix
    ./uc3
  ];

  lib.agents = {
    # name -> SKILL.md contents
    skillFiles =
      config.lib.agents.skills
      |> mapAttrs (
        name: v:
        concatStringsSep "\n" [
          "---"
          "name: ${name}"
          "description: ${v.description}"
          "---"
          v.text
        ]
      );
  };

  home = {
    packages = with pkgs; [
      caut # codex/claude usage
      inspector
    ];
  };
}
