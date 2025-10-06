{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins)
    mapAttrs
    ;

  # TODO move to separate file
  flakes =
    final: prev:
    (mapAttrs (n: v: v.packages.${prev.system}.default) {
      inherit (inputs)
        subcat
        mcp-nixos
        nil
        mdformat-myst
        claude-desktop
        mods
        zotero-mcp
        todo
        duckduckgo-mcp-server
        statix
        deadnix
        ;
    });

  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (prev) config system; })
      copilot-lua
      github-mcp-server
      keymapp
      proton-pass
      librewolf
      litellm
      ghostty
      ;
  };

  impureWrappers =
    final: prev:
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
