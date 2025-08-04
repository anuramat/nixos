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
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
      opencode
      codebuff
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
      copilot-api = mkNpx "copilot-api";
      ccusage = mkNpx "ccusage";
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
          hash = "sha256-SfYprr93YsQtoyiFl2rLuaqwGyWLmqlAuhfzHztaLC4=";
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
        version = inputs.crush.shortRev;
        src = inputs.crush;
        doCheck = false;
        vendorHash = "sha256-aI3MSaQYUOLJxBxwCoVg13HpxK46q6ZITrw1osx5tiE=";
      };

      codex = pkgs.stdenv.mkDerivation {
        pname = "codex";
        version = "0.11.0";
        src = pkgs.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v0.11.0/codex";
          hash = "sha256-ARV2anuZPwxIh/5UaRgW8i7A+evA9oqq10lf4Rvu4LU=";
        };
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          makeWrapper ${pkgs.dotslash}/bin/dotslash $out/bin/codex --add-flags $src
        '';
      };

      # https://github.com/antinomyhq/forge/releases/download/v0.104.3/forge-x86_64-unknown-linux-musl
      forge = pkgs.stdenv.mkDerivation rec {
        pname = "forge";
        version = "0.104.3";
        src = pkgs.fetchurl {
          url = "https://github.com/antinomyhq/forge/releases/download/v${version}/forge-x86_64-unknown-linux-musl";
          hash = "sha256-3T+CmQtHZYzdK/r3u69KH43HGZhRHPOjPR0J4KkLuEs=";
        };
        dontUnpack = true;
        installPhase = ''
          install -Dm755 $src $out/bin/forge
        '';
      };

      vimPlugins = prev.vimPlugins // {
        avante-nvim = prev.vimPlugins.avante-nvim.overrideAttrs (old: {
          src = inputs.avante;
        });
      };

    })
  ];
}
