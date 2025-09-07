let
  lib = (import <nixpkgs> { }).lib;
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
  "cerebras.age"
  "cerebras-org.age"
  "claudecode.age"
  "gemini.age"
  "ghmcp.age"
  "groq.age"
  "oai.age"
  "openrouter.age"
  "zai.age"
]
|> map (x: {
  name = x;
  value = {
    publicKeys = keys;
  };
})
|> lib.listToAttrs
