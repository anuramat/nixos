rec {
  epsilon =
    path: path |> builtins.readDir |> builtins.attrNames |> builtins.filter (a: a != "default.nix");
  dummy = path: path |> epsilon |> map (name: path + /${name});
}
