{
  lib,
  username ? null,
  config,
  root,
  ...
}:
let
  isNixOS = config ? system;
  secretsRoot = /${root}/secrets;
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
      // (
        if isNixOS then
          {
            owner = username;
          }
        else
          { }
      );
    })
    |> builtins.listToAttrs;
}
