{
  lib,
  inputs,
  config,
  ...
}:
let
  isNixOS = config ? system;
  secretsRoot = ../secrets;
in
{
  age.secrets =
    with builtins;
    readDir secretsRoot
    |> attrNames
    |> filter (lib.hasSuffix ".age")
    |> map (x: {
      name = lib.removeSuffix ".age" x;
      value = {
        file = /${secretsRoot}/${x};
      }
      // lib.optionalAttrs isNixOS { owner = inputs.self.user.username; };
    })
    |> builtins.listToAttrs;
}
