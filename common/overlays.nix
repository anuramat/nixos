{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) splitString;
  inherit (builtins)
    head
    filter
    mapAttrs
    readFile
    match
    length
    replaceStrings
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
        modagent
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
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

      ollama = prev.ollama.overrideAttrs (oldAttrs: rec {
        version = "0.11.3";
        src = prev.fetchFromGitHub {
          owner = "ollama";
          repo = "ollama";
          tag = "v${version}";
          hash = "sha256-FghgCtVQIxc9qB5vZZlblugk6HLnxoT8xanZK+N8qEc=";
          fetchSubmodules = true;
        };
        vendorHash = "sha256-SlaDsu001TUW+t9WRp7LqxUSQSGDF1Lqu9M1bgILoX4=";
      });

      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "1.0.69";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-uZbe7N3FSAVxNxL7npujJcBFH6ZjnwDz327bZWN2IEM=";
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

      mods = prev.buildGoModule rec {
        pname = "mods";
        meta.mainProgram = pname;
        version = inputs.mods.shortRev;
        src = inputs.mods;
        doCheck = false;
        vendorHash = "sha256-Io6aNX7z6UvEAIt4qrxF0DA7/yqc8XIMG/bRVlE3nQU=";
      };

      codex = pkgs.stdenv.mkDerivation rec {
        pname = "codex";
        version = "0.19.0";
        src = pkgs.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex";
          hash = "sha256-w3xGaY5TEoZ4wbHmYw2F8Myel0Sn7CkVsuo4NydK4to=";
        };
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          makeWrapper ${pkgs.dotslash}/bin/dotslash $out/bin/codex --add-flags $src
        '';
      };

      vimPlugins = prev.vimPlugins // {
        avante-nvim = prev.vimPlugins.avante-nvim.overrideAttrs (old: {
          src = inputs.avante;
        });
        blink-cmp-avante = prev.vimPlugins.blink-cmp-avante.overrideAttrs (old: {
          src = inputs.blink-cmp-avante;
        });
      };

      # Fetch Cursor install script, extract DOWNLOAD_URL, fetch the tarball,
      # take index.js, and wrap it to run with nodejs 22.
      cursor-index =
        let
          installer = prev.fetchurl {
            url = "https://cursor.com/install";
            hash = "sha256-iagH6czXKURghLH/i0lhEAIYnoy9iQJVOdEmBZBSFnE=";
          };
          installerText = readFile installer;
          matches =
            splitString "\n" installerText
            |> map (x: x |> match ''DOWNLOAD_URL="(.*)"'')
            |> filter (x: x != null);
          len = length matches;
          linkTemplate =
            if len != 1 then
              throw "cursor-index: ${len} matches for DOWNLOAD_URL in install script:\n\n${installerText}"
            else
              matches |> head |> head;
          link = replaceStrings [ "\${OS}" "\${ARCH}" ] [ "linux" "x64" ] linkTemplate;
          tarball = prev.fetchurl {
            url = link;
          };
          version = "nightly";
        in
        prev.stdenv.mkDerivation rec {
          pname = "cursor";
          version = "unstable";
          src = tarball;
          phases = [
            "unpackPhase"
            "installPhase"
          ];
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/cursor $out/bin
            found="$(find . -type f -name index.js | head -n1 || true)"
            if [ -z "$found" ]; then
              echo "index.js not found in tarball" >&2
              exit 1
            fi
            install -Dm644 "$found" "$out/share/cursor/index.js"
            cat >$out/bin/cursor <<'EOF'
            #!${prev.runtimeShell}
            exec ${prev.nodejs_22}/bin/node "$(dirname "$0")/../share/cursor/index.js" "$@"
            EOF
            chmod +x $out/bin/cursor
            runHook postInstall
          '';
          meta = with prev.lib; {
            description = "Run Cursor-distributed index.js via Node.js 22";
            platforms = platforms.linux;
            mainProgram = "cursor";
          };
        };

    })
  ];
}
