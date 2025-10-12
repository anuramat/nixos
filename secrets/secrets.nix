let
  inherit (import <nixpkgs> { }) lib;
  keys =
    let
      flake = builtins.getFlake (toString ../.);
      names = builtins.attrNames flake.outputs.nixosConfigurations;
      inherit
        (import ../hax/hosts.nix {
          inherit lib;
          inputs = flake.inputs // {
            self = flake.outputs;
          };
        })
        mkKeyFiles
        mkHostKeys
        ;
      clientKeys = mkKeyFiles names |> map builtins.readFile |> map lib.trim;
      hostKeys = mkHostKeys names;
    in
    clientKeys ++ hostKeys;
in
[
  "anthropic.age"
  "cerebras-free.age"
  "cerebras.age"
  "claude.age"
  "gemini.age"
  "groq.age"
  "openai.age"
  "openrouter.age"
  "perplexity.age"
  "zai.age"

  "ollama.age"
  "ghmcp.age"
]
|> map (x: {
  name = x;
  value = {
    publicKeys = keys;
  };
})
|> lib.listToAttrs
