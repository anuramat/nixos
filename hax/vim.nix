{ lib, ... }:
let
  lua = action: { __raw = action; };
  toJSON = lib.generators.toJSON { };

  fileKinds = {
    ftp = {
      prefix = "after/ftplugin/";
      suffix = ".lua";
      toValue = v: { localOpts = v; };
    };
    injections = {
      prefix = "after/queries/";
      suffix = "/injections.scm";
      toValue = v: { text = v; };
    };
    textobjects = {
      prefix = "after/queries/";
      suffix = "/textobjects.scm";
      toValue = v: { text = v; };
    };
    snippets = {
      prefix = "snippets/";
      suffix = ".json";
      toValue = v: { text = toJSON v; };
    };
  };
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
            desc = if desc == "" then action else desc;
          };
        }
      else if type == "set" then
        { }
      else
        throw "type ${type} is invalid for vim keymaps"
    );

  files =
    specs:
    let
      # Create a list of all filetype/kind combinations with their properly named attributes
      fileAttrsList = lib.concatMap (
        ft:
        lib.concatMap (
          kind:
          let
            value = specs.${ft}.${kind};
            meta =
              if builtins.hasAttr kind fileKinds then
                fileKinds.${kind}
              else
                throw "unknown vim file kind ${kind}";
            name = meta.prefix + ft + meta.suffix;
            transformedValue = meta.toValue value;
          in
          [ { ${name} = transformedValue; } ]
        ) (lib.attrNames specs.${ft})
      ) (lib.attrNames specs);
    in
    lib.foldl' lib.recursiveUpdate { } fileAttrsList;
}
