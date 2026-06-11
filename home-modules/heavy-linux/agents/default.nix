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

  summarize = pkgs.writeShellApplication {
    name = "summarize";
    runtimeInputs = with pkgs; [
      fd
      gum
      mods
    ];
    text =
      let
        find = "fd -e txt --max-depth=1";
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
    ./instructions.nix
    ./mods.nix
    ./sandbox.nix
    ./uc3
    ./whisper.nix
  ];

  lib.agents = {
    varNames = {
      sandboxWrapperPath = "AGENT_SANDBOX_WRAPPER_PATH";
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
      summarize
      inspector
    ];
  };
}
