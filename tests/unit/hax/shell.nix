{ pkgs, lib }:
let
  hax = import ../../../hax/shell.nix { inherit lib pkgs; };
in
{
  testGitHook = {
    expr = 
      let hook = hax.gitHook "echo 'Running hook'";
      in hook != null && lib.isDerivation hook;
    expected = true;
  };
  
  testMkNpx = {
    expr = 
      let npxPkg = hax.mkNpx "typescript";
      in npxPkg != null && lib.isDerivation npxPkg;
    expected = true;
  };
  
  testMkNpxLink = {
    expr = 
      let npxPkg = hax.mkNpxLink "tsc" "typescript";
      in npxPkg != null && lib.isDerivation npxPkg;
    expected = true;
  };
  
  testMkShellCheckConfig = {
    expr = hax.mkShellCheckConfig [ 2016 2059 2292 ];
    expected = ''
      disable=SC2016
      disable=SC2059
      disable=SC2292
    '';
  };
  
  testMkShellCheckConfigEmpty = {
    expr = hax.mkShellCheckConfig [];
    expected = "";
  };
  
  testMkShellCheckConfigSingle = {
    expr = hax.mkShellCheckConfig [ 1003 ];
    expected = "disable=SC1003\n";
  };
}