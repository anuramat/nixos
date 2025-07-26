{ lib, ... }:
let
  x = with builtins; readDir ./. |> attrNames |> filter (a: lib.hasSuffix ".age");
in
{
  age = {
    secrets = {
      ghmcp.file = ./ghmcp.age;
      litellm.file = ./litellm.age;
    };
  };
}
