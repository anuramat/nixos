{
  inputs,
  lib,
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
        mods
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (prev) config system; })
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

  inputOverlays =
    with inputs;
    [
      neovim-nightly-overlay
      nur
    ]
    |> map (v: v.overlays.default);

  overlays = inputOverlays ++ [
    npxHacks
    unstablePkgs
    pythonPackages
    flakes
    (final: prev: {

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
        version = "1.0.77";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-xs2NFxYXUW1/ge1cZiiSEhAUjsZXhDZ47VbNw+vf9bY=";
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

      codex = prev.stdenv.mkDerivation rec {
        pname = "codex";
        version = "0.19.0";
        src = prev.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex";
          hash = "sha256-w3xGaY5TEoZ4wbHmYw2F8Myel0Sn7CkVsuo4NydK4to=";
        };
        dontUnpack = true;
        nativeBuildInputs = [ prev.makeWrapper ];
        installPhase = ''
          makeWrapper ${prev.dotslash}/bin/dotslash $out/bin/codex --add-flags $src
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

      llama-cpp = prev.llama-cpp.overrideAttrs (old: rec {
        version = "6133";
        src = prev.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b${version}";
          hash = "sha256-l9MjEPvteoO0vl2J9EKLpy9Z4e/N9xOgk5PkwB5yPH8=";
          leaveDotGit = true;
          postFetch = ''
            git -C "$out" rev-parse --short HEAD >$out/COMMIT
            find "$out" -name .git -print0 | xargs -0 rm -rf
          '';
        };
      });

      cursor-agent =
        let
          installer = prev.fetchurl {
            url = "https://cursor.com/install";
            hash = "sha256-MZT1x7Ckq9LeaSzEcf2TeWmISp6Uje8sqhZ11TskYbc=";
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
            hash = "sha256-ikoxUvpLMngDOlHawq7i69mOcPGkV8q1capDU83QMWs=";
          };
          version = "nightly";
        in
        prev.stdenv.mkDerivation rec {
          pname = "cursor-agent";
          inherit version;

          src = tarball;

          nativeBuildInputs = [
            prev.autoPatchelfHook
            prev.stdenv.cc.cc.lib # is this ok? TODO
          ];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/share/cursor-agent
            cp -r * $out/share/cursor-agent/
            ln -s $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent
            runHook postInstall
          '';

          passthru.updateScript = ./update.sh;

          meta = {
            description = "Cursor CLI";
            homepage = "https://cursor.com/cli";
            license = lib.licenses.unfree;
            mainProgram = "cursor-agent";
          };
        };

    })
  ];
in
{
  default =
    final: prev:
    let
      unwrapped = map (x: x final prev) overlays;
      merge = lib.fold (a: b: a // b) { };
    in
    merge unwrapped;
}
