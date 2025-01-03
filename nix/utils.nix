let
  epsilon =
    path: path |> builtins.readDir |> builtins.attrNames |> builtins.filter (a: a != "default.nix");
in
{
  inherit epsilon;
  dummy = path: path |> epsilon |> map (name: path + /${name});
}
