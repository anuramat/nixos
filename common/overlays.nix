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
        subcat
        mcp-nixos
        nil
        ;
    });

  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
      fuse-overlayfs
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
    [
      inputs.neovim-nightly-overlay
    ]
    |> map (v: v.overlays.default);
in
{
  nixpkgs.overlays = overlays ++ [
    unstablePkgs
    flakes
    (final: prev: {
      codex = inputs.codex.packages.x86_64-linux.codex-cli;
      amp-cli = prev.amp-cli.overrideAttrs (oldAttrs: rec {
        version = "0.0.1749960449-gc74a77";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
          hash = "sha256-Bl6FAwhUF5pdS6a8YNlRU8DyD8FPCPpBWBX6/gc/TTI=";
        };
      });
      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "1.0.21";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-CtNY7CduAg/QWs58jFnJ/3CMRpRKrJzD49Gqw7kSsao=";
        };
      });

      # image-nvim = callPackage (
      #     {
      #       buildLuarocksPackage,
      #       fetchurl,
      #       fetchzip,
      #       luaOlder,
      #       magick,
      #     }:
      #     buildLuarocksPackage {
      #       pname = "image.nvim";
      #       version = "1.3.0-1";
      #       knownRockspec =
      #         (fetchurl {
      #           url = "mirror://luarocks/image.nvim-1.3.0-1.rockspec";
      #           sha256 = "1ls3v5xcgmqmscqk5prpj0q9sy0946rfb2dfva5f1axb5x4jbvj9";
      #         }).outPath;
      #       src = fetchzip {
      #         url = "https://github.com/3rd/image.nvim/archive/v1.3.0.zip";
      #         sha256 = "0fbc3wvzsck8bbz8jz5piy68w1xmq5cnhaj1lw91d8hkyjryrznr";
      #       };
      #
      #       disabled = luaOlder "5.1";
      #       propagatedBuildInputs = [ magick ];
      #
      #       meta = {
      #         homepage = "https://github.com/3rd/image.nvim";
      #         description = "🖼️ Bringing images to Neovim.";
      #         maintainers = with lib.maintainers; [ teto ];
      #         license.fullName = "MIT";
      #       };
      #     }
      #   ) { };
    })
  ];
}
