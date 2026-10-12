{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    ;
in

{

  imports = [
    ./commands.nix
    ./feedback.nix
    ./frontends
    ./hostrun
    ./instructions.nix
    ./job.nix
    ./relay
    ./sandbox.nix
    ./uc3
  ];

  lib.agents = {
    prependFrontmatter =
      text: fields:
      let
        fm = fields |> mapAttrsToList (n: v: n + ": " + v) |> concatStringsSep "\n";
      in
      [
        "---"
        fm
        "---"
        text
      ]
      |> concatStringsSep "\n";

    mkCommandFiles =
      dir:
      config.lib.agents.commands
      |> lib.mapAttrs' (
        n: v: lib.nameValuePair "${dir}/${n}.md" { text = v.withFM { inherit (v) description; }; }
      );
  };

  home = {
    packages = with pkgs; [
      inspector
    ];
  };
}
