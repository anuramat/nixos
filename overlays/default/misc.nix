inputs:
(final: prev: {
  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: rec {
    version = "3.21.2";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

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
    version = "1.0.123";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-bzI6wYnY3kBA8xKOeQqYpsi672FIrcSj3eAN0nFqz5o=";
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

  codex = prev.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.41.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.zst";
      hash = "sha256-QUbK/Q96nq+JDsaPESappaJKZ7NST3PD9+XQb4WNIiQ=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ prev.zstd ];
    installPhase = ''
      zstd -d "$src" -o codex
      install -Dt $out/bin codex
      mkdir -p $out/share/bash-completion/completions
      $out/bin/codex completion bash >$out/share/bash-completion/completions/codex
    '';
    meta.mainProgram = "codex";
  };

  opencode = prev.stdenvNoCC.mkDerivation rec {
    pname = "opencode";
    version = "0.10.4";
    src = prev.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      hash = "sha256-kQ6WwrNZuRz7Dk+5EbubIAEOc2vMc7A2EtFlXlUaxX4=";
    };
    dontFixup = true;
    # dontStrip = true;
    # dontPatchELF = true;
    installPhase = ''
      runHook preInstall
      install -Dt $out/bin opencode
      runHook postInstall
    '';
    meta = {
      description = "Opencode CLI tool";
      homepage = "https://github.com/sst/opencode";
      license = prev.lib.licenses.mit;
      mainProgram = "opencode";
    };
  };

  llmapibenchmark = prev.stdenvNoCC.mkDerivation rec {
    pname = "llmapibenchmark";
    version = "1.0.5";
    src = prev.fetchurl {
      url = "https://github.com/Yoosu-L/llmapibenchmark/releases/download/v${version}/llmapibenchmark_linux_amd64.tar.gz";
      hash = "sha256-8cqlHwvEObTHM9wNmfEU5jVney/ZWYnKzjTVxka2j0A=";
    };
    dontBuild = true;
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      tar -xzf "$src" llmapibenchmark_linux_amd64
      install -Dm755 llmapibenchmark_linux_amd64 $out/bin/llmapibenchmark
      runHook postInstall
    '';
    meta = {
      description = "Benchmark OpenAI-compatible inference APIs";
      homepage = "https://github.com/Yoosu-L/llmapibenchmark";
      license = prev.lib.licenses.gpl3Only;
      mainProgram = "llmapibenchmark";
    };
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

})
