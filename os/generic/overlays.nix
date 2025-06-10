{
  inputs,
  pkgs,
  ...
}@args:
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

  overrides = import ./overrides.nix args;
in
{
  nixpkgs.overlays = overlays ++ [
    overrides
    unstablePkgs
    flakes
    (final: prev: {
      codex = inputs.codex.packages.x86_64-linux.codex-cli;
      # ollama = prev.ollama.overrideAttrs (oldAttrs: rec {
      #   version = "0.9.0-rc0";
      #   src = prev.fetchFromGitHub {
      #     owner = "ollama";
      #     repo = "ollama";
      #     rev = "v${version}";
      #     sha256 = "sha256-+8UHE9M2JWUARuuIRdKwNkn1hoxtuitVH7do5V5uEg0=";
      #   };
      # });
      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "1.0.17";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-RxbsAehJ4zIt86ppmMB1MPg/XFrGWuumNdQbT+ytg8A=";
        };
      });
    })
  ];
}
