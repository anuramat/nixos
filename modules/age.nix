{
  lib,
  user,
  config,
  root,
  ...
}:
let
  isNixOS = config ? boot.kernelPackages;
in
{
  age.secrets =
    with builtins;
    readDir (root + "/secrets")
    |> attrNames
    |> filter (lib.hasSuffix ".age")
    |> map (x: {
      name = lib.removeSuffix ".age" x;
      value = {
        file = root + x;
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
