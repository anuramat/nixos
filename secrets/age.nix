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
      claudecode = {
        file = ./claudecode.age;
        owner = user.username;
      };
      gemini = {
        file = ./gemini.age;
        owner = user.username;
      };
      openrouter = {
        file = ./openrouter.age;
        owner = user.username;
      };
      anthropic = {
        file = ./anthropic.age;
        owner = user.username;
      };
    };
  };
}
