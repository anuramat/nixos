# OneJev's TypeSafe-compatible /v1/systemone server, `qev serve --llama-url URL`, patched for its llama.cpp engine: a
# checkpoint with a block-bidirectional mask (mammoth-1) has each question sent as noncausal_suffix, TypeSafe's images
# (top-level `images` / `files`, image parts of a chat state) become qev's media, and --max-image-tokens refuses
# larger images
_: _final: prev:
let
  # safetensors' tests need torch, which config.rocmSupport (bgm5) builds from source
  python = prev.python3.override {
    packageOverrides = _: super: {
      safetensors = super.safetensors.overridePythonAttrs { doCheck = false; };
    };
  };
in
{
  qev = python.pkgs.buildPythonApplication {
    pname = "qev";
    version = "0.1.0-unstable-2026-10-01";
    pyproject = true;
    src = prev.fetchFromGitHub {
      owner = "OmniJev";
      repo = "OneJev";
      rev = "81ce62f1597c91e46767d4d02d6ac2e18534fe94";
      hash = "sha256-CwNkcFIMXyriFe1K8z9flGOFuF4WeZiobM0XIuZQhMM=";
    };
    patches = [ ./llama-cpp.patch ];
    build-system = [ python.pkgs.setuptools ];
    dependencies = with python.pkgs; [
      transformers
      pillow
      jinja2
      pydantic
      fastapi
      uvicorn
    ];
    pythonImportsCheck = [
      "qev.server"
      "qev.llamacpp"
    ];
    meta.mainProgram = "qev";
  };
}
