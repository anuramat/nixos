{
  lib,
  user,
  config,
  ...
}:
let
  isNixOS = config ? boot.kernelPackages;
  isHomeManager = config ? home.username;
in
{
  age.secrets =
    assert isNixOS || isHomeManager;
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
