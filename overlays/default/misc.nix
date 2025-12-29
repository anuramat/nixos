inputs:
(final: prev: {
  web-search-mcp =
    let
      # TODO
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

  # TODO this requires fastuuid which is not in nixpkgs
  # litellm = prev.litellm.overrideAttrs (_: rec {
  #   version = "1.77.7.rc.2";
  #   src = prev.fetchFromGitHub {
  #     owner = "BerriAI";
  #     repo = "litellm";
  #     tag = "v${version}";
  #     hash = "sha256-utXxzyx99O+/1VqumBnafh85cRZsk3cIrVjG/wdv6yk=";
  #   };
  # });

  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: {
    version = "unstable";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.0.76";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-46IqiGJZrZM4vVcanZj/vY4uxFH3/4LxNA+Qb6iIHDk=";
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
    version = "0.65.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.zst";
      sha256 = "sha256-S3BfkdJunJcm+GH192/GdP5KiEbaslt1sVhs8mNhOos=";
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

})
