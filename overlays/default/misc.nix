inputs:
(final: prev: {

  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: {
    version = "unstable";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

  claude-code = prev.stdenv.mkDerivation rec {
    pname = "claude-code";
    version = "2.1.71";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-UAzKro3PgcZcAP3/3yXGU7DE+A4E8URtV+InMfyJrd4=";
    };
    nativeBuildInputs = [ prev.makeWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/claude-code $out/bin
      cp -r . $out/lib/claude-code
      makeWrapper ${prev.nodejs}/bin/node $out/bin/claude \
        --add-flags $out/lib/claude-code/cli.js \
        --set DISABLE_AUTOUPDATER 1 \
        --unset DEV
      runHook postInstall
    '';
    meta = prev.claude-code.meta // {
      mainProgram = "claude";
    };
    # https://www.npmjs.com/package/@anthropic-ai/claude-code
    # https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
  };

  codex = prev.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.112.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.zst";
      sha256 = "sha256-EsYLexTGY6Dqn4j+p1nbEjwSieb3N0lFdVdlie0xAY0=";
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

  agentfs = prev.stdenv.mkDerivation rec {
    pname = "agentfs";
    version = "0.6.0";
    src = prev.fetchzip {
      url = "https://github.com/tursodatabase/agentfs/releases/download/v${version}/agentfs-x86_64-unknown-linux-gnu.tar.xz";
      hash = "sha256-JWevVEE/AYzbc4/LiQR46BelGwnM/vWheR/s2U8nI4g=";
    };
    installPhase = ''
      runHook preInstall
      install -Dt $out/bin agentfs
      runHook postInstall
    '';
    meta.mainProgram = "agentfs";
  };

  # llama-cpp = prev.llama-cpp.overrideAttrs (_: rec {
  #   version = "";
  #   src = prev.fetchFromGitHub {
  #     owner = "ggml-org";
  #     repo = "llama.cpp";
  #     tag = "b${version}";
  #     hash = "";
  #   };
  # });

})
