let
  lib = (import <nixpkgs> { }).lib;
  inherit (import ../hax/hosts.nix { inherit lib; }) getAllKeys getAllHostkeys;
  # TODO one of these is not used
  hostkeys = getAllHostkeys ../hosts;
  keyPaths = getAllKeys ../hosts;
  keys = hostkeys ++ map (v: builtins.readFile v) keyPaths;
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
