{
  pkgs,
  config,
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
    ./git.nix
    ./instructions.nix
    ./mods.nix
    ./roles.nix
    ./sandbox.nix
    ./tools.nix
  ];

  # terminology:
  # context -- text automatically loaded by the agent
  # instructions -- global context

  lib.agents = {
    mainContextFile = "AGENT.md";

    contextFiles = [
      "CRUSH.md"
      "GEMINI.md"
      "CLAUDE.md"
      "AGENTS.md"
      "AGENT.md"
    ];

    varNames = {
      rwDirs = "RW_DIRS";
      agentName = "AGENT";
    };

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

    # TODO rename
    mkPrompts =
      dir: prompts:
      lib.mapAttrs' (promptName: prompt: {
        name = "${dir}/${promptName}.md";
        value = {
          text = prompt;
        };
      }) prompts;
  };

  home.packages = with pkgs; [
    openai-whisper
  ];
}
