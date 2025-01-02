# imports everything from ./.
path:
let
  filter = builtins.filter (a: a != "default.nix");
  names = path |> builtins.readDir |> builtins.attrNames |> filter;
  paths = map (name: /${path}/${name}) names;
in
{
  imports = paths;
}
