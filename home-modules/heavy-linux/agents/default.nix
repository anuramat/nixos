{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
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
    # xdg.configFile entries linking each skill's directory into DIR; agents
    # skip a symlinked SKILL.md, but follow a symlinked skill directory
    mkSkillLinks =
      dir:
      config.lib.agents.skills
      |> lib.mapAttrs' (
        name: v:
        lib.nameValuePair "${dir}/${name}" {
          source = pkgs.writeTextDir "SKILL.md" (
            concatStringsSep "\n" [
              "---"
              "name: ${name}"
              "description: ${v.description}"
              "---"
              v.text
            ]
          );
        }
      );
  };

  home = {
    packages = with pkgs; [
      caut # codex/claude usage
      inspector
    ];
  };
}
