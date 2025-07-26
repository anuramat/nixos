{ lib, user, ... }:
let
  sex =
    with builtins;
    readDir ./.
    |> attrNames
    |> filter (lib.hasSuffix ".age")
    |> map (x: {
      name = lib.removeSuffix ".age" x;
      value = ./${x};
    })
    |> builtins.listToAttrs;
in
{
  age = {
    secrets = {
      ghmcp = {
        file = ./ghmcp.age;
        owner = user.username;
      };
      litellm = {
        file = ./litellm.age;
        mode = "400";
      };
    };
  };
}
