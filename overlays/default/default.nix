{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins)
    mapAttrs
    ;

  flakes =
    _: prev:
    (mapAttrs (_: v: v.packages.${prev.stdenv.hostPlatform.system}.default) {
      inherit (inputs)
        subcat
        mcp-nixos
        nil
        mods
        zotero-mcp
        todo
        duckduckgo-mcp-server
        statix
        deadnix
        html2text
        ;
    });

  unstablePkgs =
    _: prev:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev) config;
        inherit (prev.stdenv.hostPlatform) system;
      };
    in
    {
      inherit (unstable)
        litellm
        opencode
        ;
    };

  impureWrappers =
    _: prev:
    let
      mkNpx =
        binName: pkg:
        let
          npx = prev.lib.getExe' prev.nodejs "npx";
        in
        prev.writeShellScriptBin binName ''
          exec ${npx} -y ${pkg} "$@"
        '';
      mkUv =
        binName: pkg:
        let
          uv = prev.lib.getExe prev.uv;
        in
        prev.writeShellScriptBin binName ''
          exec ${uv} tool run ${pkg} "$@"
        '';
    in
    {
      qwen-code = mkNpx "qwen-code" "@qwen-code/qwen-code";
      gemini-cli = mkNpx "gemini" "@google/gemini-cli";
      inspector = mkNpx "inspector" "@modelcontextprotocol/inspector";
      ccusage = mkNpx "ccusage" "ccusage";
      ccusage-codex = mkNpx "ccusage-codex" "@ccusage/codex";
      perplexity-mcp = mkNpx "perplexity-mcp" "@perplexity-ai/mcp-server";
      claude-monitor = mkUv "claude-monitor" "claude-monitor";
    };

  inputOverlays =
    with inputs;
    [
      neovim-nightly-overlay
      # nur
    ]
    |> map (v: v.overlays.default);

  overlays = inputOverlays ++ [
    (import ./misc.nix inputs)
    # (import ./llama-cpp.nix inputs)
    (import ./vim-plugins.nix inputs)
    impureWrappers
    unstablePkgs
    flakes
  ];
in
final: prev:
let
  unwrapped = map (x: x final prev) overlays;
  merge = lib.fold (a: b: a // b) { };
in
merge unwrapped
