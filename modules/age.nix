{
  lib,
  user,
  config,
  root,
  ...
}:
let
  isNixOS = config ? boot.kernelPackages;
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
            owner = user.username;
          }
        else
          { }
      );
    })
    |> builtins.listToAttrs;
}
