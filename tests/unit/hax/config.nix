{ pkgs, lib }:
let
  hax = import ../../../hax/config.nix { inherit lib pkgs; };
in
{
  testMkSettingsJSON = {
    expr = hax.mkSettingsJSON "/config" {
      "/settings.json" = { key = "value"; };
      "/data.json" = { items = [ 1 2 3 ]; };
    };
    expected = {
      "/config/settings.json" = { text = ''{"key":"value"}''; };
      "/config/data.json" = { text = ''{"items":[1,2,3]}''; };
    };
  };
  
  testMkSettingsJSONEmpty = {
    expr = hax.mkSettingsJSON "/root" {};
    expected = {};
  };
  
  testMkJsonBasic = {
    expr = 
      let result = hax.mkJson "test.json" { enabled = true; count = 42; };
      in { inherit (result) raw text; hasFile = result.file != null; };
    expected = {
      raw = { enabled = true; count = 42; };
      text = ''{"count":42,"enabled":true}'';
      hasFile = true;
    };
  };
  
  testMkJsonNested = {
    expr = 
      let result = hax.mkJson "config.json" { 
        settings = { theme = "dark"; fontSize = 14; };
        features = [ "spell-check" "auto-save" ];
      };
      in result.text;
    expected = ''{"features":["spell-check","auto-save"],"settings":{"fontSize":14,"theme":"dark"}}'';
  };
  
  testAssign = {
    expr = hax.assign "DP-1" [ "1" "2" "3" ];
    expected = [
      { workspace = "1"; output = "DP-1"; }
      { workspace = "2"; output = "DP-1"; }
      { workspace = "3"; output = "DP-1"; }
    ];
  };
  
  testAssignEmpty = {
    expr = hax.assign "HDMI-1" [];
    expected = [];
  };
  
  testAssignSingle = {
    expr = hax.assign "eDP-1" [ "10" ];
    expected = [ { workspace = "10"; output = "eDP-1"; } ];
  };
}