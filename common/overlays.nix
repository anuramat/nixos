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

  oldPkgs = final: prev: {
    inherit (import inputs.nixpkgs-old { inherit (pkgs) config system; })
      nvi
      ;
  };
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

          meta = with prev.lib; {
            description = "An mdformat plugin for markdown-it-deflist";
            homepage = "https://github.com/executablebooks/mdformat-deflist";
            license = licenses.mit;
            maintainers = [ ];
          };
        };
      };
    };
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
    pythonPackages
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
        version = "1.0.31";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-DrjR1LHnLXk2cW3zXO1jxc3octITMq6t28E2KJHBxZE=";
        };
      });
    })
  ];
}
