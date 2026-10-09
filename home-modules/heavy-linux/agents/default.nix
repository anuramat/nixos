{
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

    # TODO inline?
    mkPrompts =
      dir: prompts:
      lib.mapAttrs' (promptName: prompt: {
        name = "${dir}/${promptName}.md";
        value = {
          text = prompt;
        };
      }) prompts;
  };

  home = {
    packages = with pkgs; [
      inspector
    ];
  };
}
