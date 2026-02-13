inputs:
(final: prev: {

  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: {
    version = "unstable";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.1.37";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-ijyZCT4LEEtXWOBds8WzizcfED9hVgaJByygJ4P4Yss=";
    };
    # https://www.npmjs.com/package/@anthropic-ai/claude-code
    # https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
  });

  codex = prev.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.98.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.zst";
      sha256 = "sha256-xJ7zGfOc353I2K09fy1vOIzajJ37AffYB6g3YLmYquc=";
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

  llama-cpp = prev.llama-cpp.overrideAttrs (_: rec {
    version = "7844";
    src = prev.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "b${version}";
      hash = "sha256-LA4o2WmiMEd8Q44aEtr2RRq9nJrIPpbOFmoKZyCpcjs=";
    };
  });

})
