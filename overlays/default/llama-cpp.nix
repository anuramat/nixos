inputs:
(final: prev: {
  llama-cpp = prev.llama-cpp.overrideAttrs (old: rec {
    version = "6750";
    cmakeFlags = old.cmakeFlags ++ [
      "-DLLAMA_LLGUIDANCE=ON"
    ];
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
