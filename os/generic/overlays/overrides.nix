(final: prev: {
  # ollama = prev.ollama.overrideAttrs (oldAttrs: rec {
  #   version = "0.9.0-rc0";
  #   src = prev.fetchFromGitHub {
  #     owner = "ollama";
  #     repo = "ollama";
  #     rev = "v${version}";
  #     sha256 = "sha256-+8UHE9M2JWUARuuIRdKwNkn1hoxtuitVH7do5V5uEg0=";
  #   };
  # });
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
    version = "1.0.17";
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-RxbsAehJ4zIt86ppmMB1MPg/XFrGWuumNdQbT+ytg8A=";
    };
  });
})
