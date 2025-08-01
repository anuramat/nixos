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
        mdformat-myst
        claude-desktop
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
      opencode
      litellm
      playwright-mcp
      github-mcp-server
      keymapp
      proton-pass
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
      codex = inputs.codex.packages.x86_64-linux.codex-rs;
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
      ccusage =
        # TODO pure vibes
        let
          version = "15.5.2";
        in
        prev.runCommand "ccusage-${version}"
          {
            buildInputs = [ prev.nodejs ];
            src = prev.fetchzip {
              url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
              hash = "sha256-OCWpQiFk8L/X4tRIuKFlRNYlpk1n6rPTKgVtU27usiA=";
            };
          }
          ''
            mkdir -p $out/bin $out/lib/ccusage
            cp -r $src/* $out/lib/ccusage/
            cat > $out/bin/ccusage << EOF
            #!/bin/sh
            exec ${prev.nodejs}/bin/node $out/lib/ccusage/dist/index.js "\$@"
            EOF
            chmod +x $out/bin/ccusage
          '';
      gemini-cli = prev.gemini-cli.overrideAttrs (oldAttrs: rec {
        version = "0.1.14";
        src = inputs.gemini;
        npmDeps = prev.fetchNpmDeps {
          inherit src;
          hash = "sha256-9T31QlffPP6+ryRVN/7t0iMo+2AgwPb6l6CkYh6839U=";
        };

        # TODO the rest was vibecoded:
        preConfigure = ''
          mkdir -p packages/generated
          echo "export const GIT_COMMIT_INFO = { commitHash: '${src.rev}' };" > packages/generated/git-commit.ts
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/{bin,share/gemini-cli/packages}
          cp -r node_modules $out/share/gemini-cli/
          rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
          rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
          cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
          cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core
          cp -r packages/vscode-ide-companion $out/share/gemini-cli/packages/vscode-ide-companion
          ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
          runHook postInstall
        '';
        postInstall = ''
          chmod +x "$out/bin/gemini"
        '';
      });
      mystmd = prev.stdenv.mkDerivation rec {
        pname = "mystmd";
        version = "1.6.0";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/mystmd/-/mystmd-${version}.tgz";
          hash = "sha256-OatP9lv2/K4W3puaGAcECOfzNMR6a2zIntsxRnnAn4Q=";
        };
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp dist/myst.cjs $out/bin/myst
          chmod +x $out/bin/myst
          runHook postInstall
        '';
      };
      crush = prev.buildGoModule rec {
        pname = "crush";
        meta.mainProgram = pname;
        version = "nightly";
        src = inputs.crush;
        doCheck = false;
        vendorHash = "sha256-P+2m3RogxqSo53vGXxLO4sLF5EVsG66WJw3Bb9+rvT8=";
      };
    })
  ];
}
