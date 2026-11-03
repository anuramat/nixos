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
    # where the user drops files for agents to read
    userSharedDir = "${config.home.homeDirectory}/shared";
    # xdg.configFile entries linking each skill's directory into DIR; agents
    # skip a symlinked SKILL.md, but follow a symlinked skill directory
    mkSkillLinks =
      dir:
      config.lib.agents.skills
      |> lib.mapAttrs' (
        name: v:
        let
          skillFile = pkgs.writeText "SKILL.md" (
            concatStringsSep "\n" [
              "---"
              "name: ${name}"
              "description: ${v.description}"
              "---"
              v.text
            ]
          );
        in
        # files are copied rather than linked, for the same reason
        lib.nameValuePair "${dir}/${name}" {
          source = pkgs.runCommand "skill-${name}" { } ''
            mkdir $out
            cp ${skillFile} $out/SKILL.md
            ${lib.concatMapAttrsStringSep "\n" (n: p: "cp -r ${p} $out/${n}") (v.files or { })}
          '';
        }
      );
  };

  # must exist before an agent starts, or the sandbox skips its bind
  systemd.user.tmpfiles.rules = [ "d ${config.lib.agents.userSharedDir} - - - -" ];

  home = {
    packages = with pkgs; [
      inspector
    ];
  };
}
