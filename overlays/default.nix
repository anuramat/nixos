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
        zotero-mcp
        ;
    });
  unstablePkgs = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (prev) config system; })
      playwright-mcp
      github-mcp-server
      keymapp
      proton-pass
      goose-cli
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
      mkNpx =
        binName: pkg:
        let
          npx = prev.lib.getExe' prev.nodejs "npx";
        in
        prev.writeShellScriptBin binName ''
          exec ${npx} -y ${pkg} "$@"
        '';
    in
    {
      gemini-cli = mkNpx "gemini" "@google/gemini-cli";
      ccusage = mkNpx "ccusage" "ccusage@latest";
      opencode = mkNpx "opencode" "opencode-ai@latest";
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

      anytype = prev.appimageTools.wrapType2 rec {
        pname = "anytype";
        version = "0.49.2";
        src = prev.fetchurl {
          url = "https://github.com/anyproto/anytype-ts/releases/download/v${version}/Anytype-${version}.AppImage";
          hash = "sha256-NA8PozwenoIClkWry1q1Z/crhieflrlJVtBLLrKwWEk=";
        };
        extraInstallCommands =
          # XXX vibecoded
          let
            appimageContents = prev.appimageTools.extractType2 {
              inherit pname version src;
            };
          in
          # bash
          ''
            # Install desktop file
            install -Dm644 ${appimageContents}/anytype.desktop $out/share/applications/${pname}.desktop
            # Install icon (use the main icon)
            install -Dm644 ${appimageContents}/anytype.png $out/share/pixmaps/${pname}.png
            # Install hicolor icons
            cp -r ${appimageContents}/usr/share/icons $out/share/
            # Fix desktop file Exec path
            substituteInPlace $out/share/applications/${pname}.desktop --replace-fail 'Exec=AppRun' 'Exec=${pname}'
          '';
        meta = prev.anytype.meta;
      };

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
        version = "1.0.96";
        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-w3KT+dZbrcrwnOl9ByZ43nuSN9ON078kCqxF7fIZ7AA=";
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

      forge =
        let
          linux = "x86_64-linux";
          darwin = "aarch64-darwin";
        in
        prev.stdenv.mkDerivation rec {
          pname = "forge";
          # https://github.com/antinomyhq/forge/releases/
          version = "0.111.0";
          meta = {
            description = "AI enabled pair programmer for Claude, GPT, O Series, Grok, Deepseek, Gemini and 300+ models";
            platforms = [
              linux
              darwin
            ];
          };
          src =
            let
              src =
                let
                  mkLink =
                    system: "https://github.com/antinomyhq/forge/releases/download/v${version}/forge-${system}";
                in
                if prev.system == linux then
                  {
                    url = mkLink "x86_64-unknown-linux-musl";
                    hash = "sha256-e0UNM660sf2hJZ/+b2TpV0BilGmiv0CBfF1f4O3f70E=";
                  }
                else if prev.system == darwin then
                  {
                    url = mkLink "forge-aarch64-apple-darwin";
                    hash = "";
                  }
                else
                  throw "illegal system";
            in
            prev.fetchurl src;
          dontUnpack = true;
          installPhase = ''
            install -Dm755 $src $out/bin/forge
          '';
        };

      codex = prev.stdenv.mkDerivation rec {
        pname = "codex";
        version = "0.27.0";
        src = prev.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex";
          hash = "";
        };
        dontUnpack = true;
        nativeBuildInputs = [ prev.makeWrapper ];
        installPhase =
          with prev; # bash
          ''
            makeWrapper ${dotslash}/bin/dotslash $out/bin/codex --add-flags $src
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
        version = "6175";
        src = prev.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b${version}";
          hash = "sha256-aoyJGyxvyoU37AGycd540w4b2DC4wNA7GkzmwaZKYRU=";
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
            hash = "sha256-sXeflhcWaBo0qoE5wPXiA9ZyT78sRW2UkMiGr13J2Fk=";
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
            hash = "sha256-046NAHLckWOvIG5WJ8p3SNiUTbelEw2eTZ+/1DvTpNY=";
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
