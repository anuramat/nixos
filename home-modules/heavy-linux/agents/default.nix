{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    filterAttrs
    ;
in

{

  imports = [
    ./commands.nix
    ./frontends
    ./instructions.nix
    ./sandbox.nix
    ./uc3
  ];

  lib.agents = {
    prependFrontmatter =
      text: fields:
      let
        fm =
          fields
          |> filterAttrs (n: v: v != null)
          |> mapAttrsToList (n: v: n + ": " + v)
          |> concatStringsSep "\n";
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
