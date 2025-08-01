{ lib, user, ... }:
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
        owner = user.username;
      };
    })
    |> builtins.listToAttrs;
}
