{
  inputs,
  ...
}:
{
  # HACK here we pepegapray that the pname and attrname in nixpkgs are equal (I think it's not true for neovim for example, pname is neovim-unwrapped or something)
  mkUnstablePackages =
    pkgfunc: final: prev:
    let
      unstable = import inputs.nixpkgs-unstable { inherit (prev) config system; };
    in
    builtins.listToAttrs (
      map (pkg: {
        name = pkg.pname;
        value = pkg;
      }) (pkgfunc unstable)
    );
  unwrapOverlays = map (input: input.overlays.default);
  unwrapPackages = (
    inputs: final: prev:
    map (
      input:
      let
        pkg = input.packages.${prev.system}.default;
      in
      {
        name = pkg.pname;
        value = pkg;
      }
    ) inputs
    |> builtins.listToAttrs
  );
}
