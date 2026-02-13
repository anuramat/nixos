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

  ghcp-models =
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

  summarize = pkgs.writeShellApplication {
    name = "summarize";
    runtimeInputs = with pkgs; [
      fd
      gum
      mods
    ];
    text =
      let
        find = ''fd -e txt --max-depth=1'';
      in
      # bash
      ''
        ${find}
        gum confirm || exit 1
        mkdir -p summaries
        ${find} -a -j 1 -x sh -c "cat '{}' | mods -R summarizer -t 'summarization: {}' 'here is the lecture transcript:' > './summaries/{/.}.md'"
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
    ./ollama.nix
    ./sandbox.nix
    ./tools.nix
    ./whisper.nix
  ];

  lib.agents = {
    varNames = {
      sandboxWrapperPath = "AGENT_SANDBOX_WRAPPER_PATH";
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
      ghcp-models
      summarize
      inspector
    ];
  };
}
