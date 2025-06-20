{ lib, ... }:
let
  lua = action: { __raw = action; };
in
{
  inherit lua;
  luaf = action: (lua "function() ${action} end");
  set =
    key: action: desc:
    let
      type = builtins.typeOf action;
    in
    {
      mode = "n";
      inherit key action;
      options = { inherit desc; };
    }
    // (
      if type == "string" then
        {
          action = "<cmd>${action}<cr>";
          options = {
            desc = (if desc == "" then action else desc);
          };
        }
      else if type == "set" then
        { }
      else
        throw "type ${type} is invalid for vim keymaps"
    );
  mkFTP =
    with lib;
    plugins: mapAttrs' (n: v: nameValuePair "after/ftplugin/${n}.lua" { localOpts = v; }) plugins;
}
