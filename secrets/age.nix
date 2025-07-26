{ lib, ... }:
let
  x = with builtins; readDir ./. |> attrNames |> filter (a: a == "suff");
in
{
  age = {
    secrets = {
      ghmcp.file = secrets/ghmcp.age;
      litellm.file = .../secrets/litellm.age;
    };
  };
}
