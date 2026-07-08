{ lib, ... }:
{
  imports =
    builtins.readDir ./.
    |> builtins.attrNames
    |> lib.filter (n: n != "default.nix")
    |> map (n: ./. + "/${n}");
}
