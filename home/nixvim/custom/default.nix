{ pkgs, inputs, ... }:
{
  extraPlugins = [
    inputs.mdmath.packages.${pkgs.system}.default
  ];
  extraConfigLua = '''';
  imports = [
    ./figtree.nix
    ./namu.nix
    ./wastebin.nix
  ];
}
