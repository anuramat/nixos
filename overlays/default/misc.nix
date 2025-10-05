inputs:
(final: prev: {
  web-search-mcp =
    let
      webSearchMcpUrl = "https://raw.githubusercontent.com/ollama/ollama-python/main/examples/web-search-mcp.py";
      webSearchMcpSha256 = "11q2hwnl4nzn9nw5m6s9c79phnnwjiqgqy4kzgjanhgfalvw47r3";
      webSearchMcpSource = prev.fetchurl {
        url = webSearchMcpUrl;
        sha256 = webSearchMcpSha256;
      };
      webSearchMcpDir = prev.linkFarm "web-search-mcp" [
        {
          name = "web-search-mcp.py";
          path = webSearchMcpSource;
        }
      ];
    in
    prev.writeShellApplication {
      name = "web-search-mcp";
      runtimeInputs = [ final.uv ];
      text = ''
        cd ${webSearchMcpDir}
        exec uv run web-search-mcp.py "$@"
      '';
    };

  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: rec {
    version = "unstable";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

  ollama = prev.ollama.overrideAttrs (oldAttrs: rec {
    version = "0.12.3";
    src = prev.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      tag = "v${version}";
      hash = "sha256-ooDGwTklGJ/wzDlAY3uJiqpZUxT1cCsqVNJKU8BAPbQ=";
      fetchSubmodules = true;
    };
    vendorHash = "sha256-SlaDsu001TUW+t9WRp7LqxUSQSGDF1Lqu9M1bgILoX4=";
    acceleration = false;
  });

  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.0.1";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-LUbDPFa0lY74MBU4hvmYVntt6hVZy6UUZFN0iB4Eno8=";
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
    version = "0.42.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.zst";
      hash = "sha256-uQTCtFqh74L7shWRw5PpQWsnBRhIG55UUFO+ldsz5RI=";
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
    version = "0.13.5";
    src = prev.fetchzip {
      url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-linux-x64.zip";
      sha256 = "sha256-q98BdEuKkzInrDJSW+BRoRuUn4xquwwT6CzGjSfshH8=";
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

  zed-editor-bin =
    let
      runtimeLibs = prev.lib.makeLibraryPath [
        prev.alsa-lib
        prev.libdrm
        prev.stdenv.cc.cc
        prev.vulkan-loader
        prev.wayland
        prev.xorg.libX11
      ];
      localeArchive = "${prev.glibcLocales}/lib/locale/locale-archive";
    in
    prev.stdenvNoCC.mkDerivation rec {
      pname = "zed-editor-bin";
      version = "0.205.6";
      src = prev.fetchurl {
        url = "https://github.com/zed-industries/zed/releases/download/v${version}/zed-linux-x86_64.tar.gz";
        hash = "sha256-LiZGLRUOZZn0kEwYaPuHts68M2uxODWIVUrQbla4YFw=";
      };
      sourceRoot = ".";
      nativeBuildInputs = [
        prev.autoPatchelfHook
        prev.makeWrapper
      ];
      buildInputs = [
        prev.alsa-lib
        prev.libdrm
        prev.stdenv.cc.cc
        prev.vulkan-loader
        prev.wayland
        prev.xorg.xkeyboardconfig
        prev.xorg.libX11
      ];
      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/zed
        cp -r zed.app/. $out/share/zed
        chmod +x $out/share/zed/bin/zed
        mkdir -p $out/bin
        makeWrapper $out/share/zed/bin/zed $out/bin/zed \
          --set-default ZED_DISABLE_AUTO_UPDATE 1 \
          --set-default XKB_CONFIG_ROOT ${prev.xorg.xkeyboardconfig}/share/X11/xkb \
          --set-default LC_ALL en_US.UTF-8 \
          --set-default LOCALE_ARCHIVE ${localeArchive} \
          --suffix LD_LIBRARY_PATH : ${runtimeLibs} \
          --suffix LD_LIBRARY_PATH : /run/opengl-driver/lib \
          --suffix XDG_DATA_DIRS : /run/opengl-driver/share
        runHook postInstall
      '';
      meta = {
        description = "Zed editor binary distribution";
        homepage = "https://zed.dev";
        license = prev.lib.licenses.gpl3Only;
        mainProgram = "zed";
        platforms = [ "x86_64-linux" ];
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
