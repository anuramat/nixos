inputs:
(final: prev: {
  crush =
    let
      unstable = (import inputs.nixpkgs-unstable { inherit (prev) config system; });
    in
    unstable.buildGo125Module rec {
      pname = "crush";
      meta.mainProgram = pname;
      version = inputs.crush.shortRev;
      src = inputs.crush;
      doCheck = false;
      vendorHash = "sha256-k7yfCyfeW2TW5DpVmxfNLXV08FxhpW4SQNAcDyrYKPc=";
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

  codex = prev.stdenv.mkDerivation rec {
    pname = "codex";
    version = "0.31.0";
    src = prev.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex";
      hash = "sha256-8fRnYhgXp+kS0LHSqZ3BNqTzmMXaS39x0GwIF1HDJOQ=";
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

})
