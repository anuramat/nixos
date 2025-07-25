{
  inputs,
  pkgs,
  lib,
  ...
}:
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
      opencode
      playwright-mcp
      github-mcp-server
      keymapp
      proton-pass
      vscode
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

  opencodeName = "opencode-alt";
in
{
  nixpkgs.overlays = overlays ++ [
    unstablePkgs
    pythonPackages
    flakes
    (final: prev: {
      # codex = inputs.codex.packages.x86_64-linux.codex-cli;
      # mystmd = prev.mystmd.overrideAttrs (oldAttrs: rec {
      #   version = "1.6.0";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "jupyter-book";
      #     repo = "mystmd";
      #     rev = "mystmd@${version}";
      #     hash = "sha256-UfKI/OBabdQlHyAhWcn37d12oviuOan4UxdTgS94lRQ=";
      #   };
      #   npmDepsHash = "sha256-ols1YxX/I58hfdi+zXgLGetRaQvHLRHEtcTpT7rdGEs=";
      #   npmDeps = final.fetchNpmDeps {
      #     inherit src;
      #     name = "${oldAttrs.pname}-${version}-npm-deps";
      #     hash = npmDepsHash;
      #   };
      # });
      amp-cli = prev.amp-cli.overrideAttrs (oldAttrs: rec {
        version = "0.0.1749960449-gc74a77";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
          hash = "sha256-Bl6FAwhUF5pdS6a8YNlRU8DyD8FPCPpBWBX6/gc/TTI=";
        };
      });
      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "1.0.60";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-ygeitenu4z9ACbezO53I2Xnk6NtE1fWVzCi3mZS7wF8=";
        };
      });
      ccusage = prev.buildNpmPackage rec {
        pname = "ccusage";
        version = "15.5.2";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
          hash = "sha256-OCWpQiFk8L/X4tRIuKFlRNYlpk1n6rPTKgVtU27usiA=";
        };
        # npmDepsHash = "";
        # dontNpmBuild = true;
      };
      # gemini-cli = prev.gemini-cli.overrideAttrs (oldAttrs: rec {
      #   version = "0.1.13";
      #   src = prev.fetchzip {
      #     url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
      #     hash = "sha256-64Aa5SvxVSAH6+4oj3k7Va1mdTgEGB+fJFZZHWfkxMw=";
      #   };
      # });
      ${opencodeName} = prev.callPackage (
        {
          lib,
          fetchFromGitHub,
          buildGoModule,
        }:
        buildGoModule (finalAttrs: {
          pname = opencodeName;
          version = "0.0.55";

          src = fetchFromGitHub {
            owner = "opencode-ai";
            repo = "opencode";
            tag = "v${finalAttrs.version}";
            hash = "sha256-UjGNtekqPVUxH/jfi6/D4hNM27856IjbepW7SgY2yQw=";
          };

          vendorHash = "sha256-Kcwd8deHug7BPDzmbdFqEfoArpXJb1JtBKuk+drdohM=";

          # TODO is this really the only way
          postInstall = ''
            mv $out/bin/opencode $out/bin/${opencodeName}
          '';

          checkFlags =
            let
              skippedTests = [
                "TestLsTool_Run"
              ];
            in
            [ "-skip=^${lib.concatStringsSep "$|^" skippedTests}$" ];

          meta = {
            mainProgram = opencodeName;
          };
        })
      ) { };
    })
  ];
}
