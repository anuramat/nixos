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
        subcat
        mcp-nixos
        nil
        mdformat-myst
        claude-desktop
        copilot-api
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

  npxHacks =
    final: prev:
    let
      mkNpx = pkg: mkNpxLink pkg pkg;
      mkNpxLink =
        binName: pkg:
        let
          npx = prev.lib.getExe' prev.nodejs "npx";
        in
        prev.writeShellScriptBin binName ''
          exec ${npx} -y ${pkg} "$@"
        '';
    in
    {
      gemini-cli = mkNpxLink "gemini" "@google/gemini-cli";
      copilot-api = mkNpx "copilot-api" "copilot-api";
      ccusage = mkNpx "ccusage" "ccusage";
    };

  overlays =
    [
      inputs.neovim-nightly-overlay
    ]
    |> map (v: v.overlays.default);

in
{
  nixpkgs.overlays = overlays ++ [
    npxHacks
    unstablePkgs
    pythonPackages
    flakes
    (final: prev: {

      amp-cli = prev.amp-cli.overrideAttrs (oldAttrs: rec {
        version = "0.0.1754236863-g8d30ac";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
          hash = "sha256-Bl6FAwhUF5pdS6a8YNlRU8DyD8FPCPpBWBX6/gc/TTI=";
        };
      });
      # https://www.npmjs.com/package/@sourcegraph/amp

      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "1.0.67";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-Ch55xuJZJ0LXDTIlC7Ya381jqeGJzYC5IDEY0hS76/M=";
        };
        # https://www.npmjs.com/package/@anthropic-ai/claude-code
        # https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
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
          install -D dist/myst.cjs $out/bin/myst
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

      codex = inputs.codex.packages.x86_64-linux.codex-rs;

      vimPlugins = prev.vimPlugins // {
        avante-nvim = prev.vimPlugins.avante-nvim.overrideAttrs (old: {
          src = inputs.avante;
        });
      };

    })
  ];
}
