{
  inputs,
  pkgs,
  ...
}:
let

  flakes =
    final: prev:
    (builtins.mapAttrs (n: v: v.packages.${prev.system}.default) {
      inherit (inputs)
        mcp-nixos
        nil
        ;
    });

  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
      github-mcp-server
      keymapp
      tgpt
      proton-pass
      aider-chat-full
      ollama
      vscode
      windsurf
      zed-editor
      ;
  };

  overlays =
    (with inputs; [
      neovim-nightly-overlay
    ])
    |> map (v: v.overlays.default)

  ;

  overrides = import ./overrides.nix;
in
{
  nixpkgs.overlays = overlays ++ [
    overrides
    unstablePkgs
    flakes
  ];
}
