{
  lib,
  user,
  config,
  ...
}:
let
  isNixOS = config ? boot.kernelPackages;
in
{
  age.secrets =
    with builtins;
    readDir ./.
    |> attrNames
    |> filter (lib.hasSuffix ".age")
    |> map (x: {
      name = lib.removeSuffix ".age" x;
      value = {
        file = ./${x};
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
