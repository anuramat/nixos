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
    final: prev:
    (mapAttrs (n: v: v.packages.${prev.system}.default) {
      inherit (inputs)
        subcat
        gothink
        mcp-nixos
        nil
        mdformat-myst
        claude-desktop
        mods
        zotero-mcp
        todo
        duckduckgo-mcp-server
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (prev) config system; })
      github-mcp-server
      keymapp
      proton-pass
      goose-cli
      librewolf
      ;
  };
  pythonPackages = final: prev: {
    python3 = prev.python3.override {
      packageOverrides = pfinal: pprev: {
        mdformat-deflist = pfinal.buildPythonPackage rec {
          pname = "mdformat_deflist";
          version = "0.1.3";
          format = "pyproject";
          src = pfinal.fetchPypi {
            inherit pname version;
            hash = "sha256-slCRzhcFo3wMyH3bHHij5+tD1Qrc21rUdjQR90Oub34=";
          };
          nativeBuildInputs = [ pfinal.flit-core ];
          propagatedBuildInputs = [
            pfinal.mdformat
            pfinal.mdit-py-plugins
          ];
          pythonImportsCheck = [ "mdformat_deflist" ];
        };
      };
    };
  };

  impureWrappers =
    final: prev:
    let
      mkBunx =
        binName: pkg:
        let
          bunx = prev.lib.getExe' prev.bun "bunx";
        in
        prev.writeShellScriptBin binName ''
          exec ${bunx} -y ${pkg} "$@"
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
      qwen-code = mkBunx "qwen-code" "@qwen-code/qwen-code";
      gemini-cli = mkBunx "gemini" "@google/gemini-cli";
      inspector = mkBunx "inspector" "@modelcontextprotocol/inspector";
      ccusage = mkBunx "ccusage" "ccusage";
      opencode = mkBunx "opencode" "opencode-ai";
      claude-monitor = mkUv "claude-monitor" "claude-monitor";
    };

  inputOverlays =
    with inputs;
    [
      neovim-nightly-overlay
      nur
    ]
    |> map (v: v.overlays.default);

  overlays = inputOverlays ++ [
    # autoimport these
    (import ./anytype.nix)
    (import ./cursor.nix)
    (import ./forge.nix)
    (import ./misc.nix inputs)
    impureWrappers
    unstablePkgs
    pythonPackages
    flakes
  ];
in
final: prev:
let
  unwrapped = map (x: x final prev) overlays;
  merge = lib.fold (a: b: a // b) { };
in
merge unwrapped
