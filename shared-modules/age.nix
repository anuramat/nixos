{
  lib,
  config,
  ...
}:
let
  isNixOS = config ? system;
  username = if isNixOS then config.userConfig.username else null;
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
