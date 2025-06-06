(final: prev: {
  ollama = prev.ollama.overrideAttrs (oldAttrs: rec {
    version = "0.9.0-rc0";
    src = prev.fetchFromGitHub {
      owner = "ollama";
      repo = "ollama";
      rev = "v${version}";
      sha256 = "sha256-+8UHE9M2JWUARuuIRdKwNkn1hoxtuitVH7do5V5uEg0=";
    };
  });
})
