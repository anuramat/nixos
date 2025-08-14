{ pkgs, lib }:
let
  hax = import ../../../hax/utils.nix { inherit lib; };
in
{
  testWhenTrue = {
    expr = hax.when true "value";
    expected = "value";
  };
  
  testWhenFalseString = {
    expr = hax.when false "value";
    expected = "";
  };
  
  testWhenFalseAttrs = {
    expr = hax.when false { key = "value"; };
    expected = {};
  };
  
  testWhenFalseList = {
    expr = hax.when false [ "item1" "item2" ];
    expected = [];
  };
  
  testWhenTrueAttrs = {
    expr = hax.when true { key = "value"; nested = { inner = 42; }; };
    expected = { key = "value"; nested = { inner = 42; }; };
  };
  
  testWhenTrueList = {
    expr = hax.when true [ "a" "b" "c" ];
    expected = [ "a" "b" "c" ];
  };
  
  testWhenNested = {
    expr = {
      config = hax.when false { setting = true; };
      list = hax.when false [ 1 2 3 ];
      string = hax.when false "text";
    };
    expected = {
      config = {};
      list = [];
      string = "";
    };
  };
}