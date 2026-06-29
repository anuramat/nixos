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

  # Each kind maps a per-filetype value to `{ target, value }`: `target` is the
  # nixvim option it lands in (`files` for managed modules compiled to lua,
  # `extraFiles` for raw runtime files), `value` its content. The file path is
  # `prefix + filetype + suffix`.
  fileKinds = {
    # ftplugin: a string is raw lua sourced verbatim (extraFiles); an attrset is
    # a managed nixvim `files` submodule -- local options shorthand, or a full
    # submodule if it already carries `localOpts` (e.g. `{ localOpts; extraConfigLua; }`).
    ftp = {
      prefix = "after/ftplugin/";
      suffix = ".lua";
      route =
        v:
        if lib.isString v then
          {
            target = "extraFiles";
            value.text = v;
          }
        else
          {
            target = "files";
            value = if v ? localOpts then v else { localOpts = v; };
          };
    };
    injections = {
      prefix = "after/queries/";
      suffix = "/injections.scm";
      route = v: {
        target = "extraFiles";
        value.text = v;
      };
    };
    snippets = {
      prefix = "snippets/";
      suffix = ".json";
      route = v: {
        target = "extraFiles";
        value.text = toJSON v;
      };
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

    # Build nixvim file content from a per-filetype spec, returning
    # `{ files, extraFiles }` partitioned by kind so callers can't misroute a
    # kind to the wrong nixvim option. Splice both back into the module with
    # `inherit`, regardless of which one a given spec actually populates:
    #
    #   inherit (mkVimFiles { sh = { ftp = {...}; snippets = {...}; }; }) files extraFiles;
    #
    # The spec is `{ <filetype> = { <kind> = value; }; }`. Each kind (see
    # `fileKinds`) fixes the on-disk path (`prefix + filetype + suffix`) and how
    # its value is interpreted:
    #   ftp        after/ftplugin/<ft>.lua       string -> raw lua (extraFiles);
    #                                             attrset -> managed `files` submodule,
    #                                             bare attrs treated as `localOpts`.
    #   injections after/queries/<ft>/injections.scm   raw scm query string.
    #   snippets   snippets/<ft>.json            attrset, encoded to JSON.
    # Unknown kinds throw. Multiple kinds/filetypes may be combined in one call.
    mkVimFiles =
      specs:
      let
        # one { target, name, value } per filetype/kind combination
        entries = lib.concatMap (
          ft:
          map (
            kind:
            let
              meta = fileKinds.${kind} or (throw "unknown vim file kind ${kind}");
            in
            {
              inherit (meta.route specs.${ft}.${kind}) target value;
              name = meta.prefix + ft + meta.suffix;
            }
          ) (lib.attrNames specs.${ft})
        ) (lib.attrNames specs);
        byTarget =
          target:
          entries
          |> lib.filter (e: e.target == target)
          |> map (e: lib.nameValuePair e.name e.value)
          |> lib.listToAttrs;
      in
      {
        files = byTarget "files";
        extraFiles = byTarget "extraFiles";
      };
  };
}
