{ inputs, unstable, ... }:
let
  unstablePackages =
    pkgs:
    builtins.listToAttrs (
      map (pkg: {
        name = pkg.pname;
        value = pkg;
      }) pkgs
    );

  unwrapOverlays = map (input: input.overlays.default);

  ollama = unstable.ollama.overrideAttrs (oldAttrs: rec {
    version = "0.9.0-rc0";
    src = unstable.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      rev = "v${version}";
      sha256 = "sha256-+8UHE9M2JWUARuuIRdKwNkn1hoxtuitVH7do5V5uEg0=";
    };
  });
in
{
  nixpkgs.overlays =
    unwrapOverlays (
      with inputs;
      [
        neovim-nightly-overlay
      ]
    )
    ++ [
      (
        final: prev:
        {
          mcp-nixos = inputs.mcp-nixos.packages.${prev.system}.default;
          inherit ollama;
        }
        // unstablePackages (
          with unstable;
          [
            github-mcp-server
          ]
        )
      )
    ];
}
