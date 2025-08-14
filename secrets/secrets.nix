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
        ;
    in
    mkKeyFiles names |> map builtins.readFile;
in
[
  "anthropic.age"
  "claudecode.age"
  "gemini.age"
  "ghmcp.age"
  "openrouter.age"
  "oai.age"
]
|> map (x: {
  name = x;
  value = {
    publicKeys = keys;
  };
})
|> lib.listToAttrs
