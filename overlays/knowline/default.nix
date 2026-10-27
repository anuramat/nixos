# KnowLine's /v1/systemone server on a llama-server backend: `knowline LLAMA_URL HOST PORT`
{ lib, ... }:
_final: prev:
let
  # the front end and the tokenizer, from the model repo
  src = prev.linkFarm "knowline-src" (
    lib.mapAttrsToList
      (name: hash: {
        inherit name;
        path = prev.fetchurl {
          url = "https://huggingface.co/PelaAI/KnowLine-35B-A3B-Gen1.5/resolve/9adcf717361b2f7d2946d093f1e85efdf1e59010/${name}";
          inherit hash;
        };
      })
      {
        "knowline_server.py" = "sha256-rZIufS1xemubk2mD/15daVNO3Fk+1UtYcy3I/2C6pn4=";
        "knowline_layout.py" = "sha256-qg+zVhn0iD7dbDvRzG3CWfQfCCz+BHHlhsYNeD2ir50=";
        "tokenizer.json" = "sha256-X55NSQGpK5l+RjwfRgVQiLbMpcphplItG59kxLuBy0I=";
        "tokenizer_config.json" = "sha256-MWIw1qgJcB9NteqPj8hivDpvMinJN8F05nT/PKCmSsg=";
        "chat_template.jinja" = "sha256-pK7or88uBxGULPhIiZvmYBb40UqIn/nt4HvKCZwo9xU=";
      }
  );
  python =
    (prev.python3.override {
      # safetensors' tests need torch, which config.rocmSupport (bgm5) builds from source
      packageOverrides = _: super: {
        safetensors = super.safetensors.overridePythonAttrs { doCheck = false; };
      };
    }).withPackages
      (p: [
        p.transformers
        p.requests
        p.jinja2
      ]);
in
{
  knowline = prev.writeShellApplication {
    name = "knowline";
    text = ''exec ${python}/bin/python -I ${./knowline.py} ${src} "$@"'';
  };
}
