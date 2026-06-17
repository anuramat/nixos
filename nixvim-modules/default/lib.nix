{ lib, ... }:
let
  lua = action: { __raw = action; };
  luaf = action: lua "function() ${action} end";

  keymap = mode: key: action: desc: {
    inherit mode key action;
    options = { inherit desc; };
  };
  # keymap that runs an ex command, sparing callers the <cmd>...<cr> wrapping
  cmd =
    mode: key: excmd: desc:
    keymap mode key "<cmd>${excmd}<cr>" desc;

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
    snippets = {
      prefix = "snippets/";
      suffix = ".json";
      toValue = v: { text = toJSON v; };
    };
  };
in
{
  options.lib = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    internal = true;
  };

  config.lib = {
    inherit
      lua
      luaf
      keymap
      cmd
      ;

    files =
      specs:
      let
        # one { path = value; } per filetype/kind combination, named by its kind
        fileAttrsList = lib.concatMap (
          ft:
          map (
            kind:
            let
              meta = fileKinds.${kind} or (throw "unknown vim file kind ${kind}");
            in
            {
              ${meta.prefix + ft + meta.suffix} = meta.toValue specs.${ft}.${kind};
            }
          ) (lib.attrNames specs.${ft})
        ) (lib.attrNames specs);
      in
      lib.mergeAttrsList fileAttrsList;
  };
}
