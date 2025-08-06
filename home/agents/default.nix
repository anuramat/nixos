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

  models =
    let
      tokenFile = config.xdg.configHome + "/github-copilot/apps.json";
    in
    pkgs.writeShellApplication {
      name = "ghcp-models";
      runtimeInputs = with pkgs; [
        jq
        curl
      ];
      text =
        # bash
        ''
          if ! [ -s "${tokenFile}" ]; then
            echo "No GitHub Copilot token found."
            exit 1
          fi
          token=$(jq -r '.[].oauth_token' '${tokenFile}') || exit 1
          curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $token" https://api.githubcopilot.com/models | jq '.data'
        '';
    };
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
    models
  ];
}
