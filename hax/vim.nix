{ lib, ... }:
let
  lua = action: { __raw = action; }; # mentioned in nix injections
  mkFile =
    prefix: suffix: f: input:
    with lib;
    mapAttrs' (n: v: nameValuePair (prefix + n + suffix) (f v)) input;
  toJSON = lib.generators.toJSON { };
in
{
  inherit lua;
  luaf = action: (lua "function() ${action} end"); # mentioned in nix injections
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
  # signature: files.* { python = "text"; }
  # rewrite this to a diff signature:
  # files = files "python" { ftp = ...; injections = ...; ...};
  files = {
    ftp = mkFile "after/ftplugin/" ".lua" (v: {
      localOpts = v;
    });
    injections = mkFile "after/queries/" "/injections.scm" (v: {
      text = v;
    });
    textobjects = mkFile "after/queries/" "/textobjects.scm" (v: {
      text = v;
    });
    snippets = mkFile "snippets/" ".json" (v: {
      text = toJSON v;
    });
  };
}
