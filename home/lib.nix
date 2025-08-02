{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    getName
    getExe
    mapAttrsToList
    concatStringsSep
    isDerivation
    isString
    isAttrs
    ;
  inherit (pkgs) writeTextFile;
  toJSON = lib.generators.toJSON { };

  fileWithJson =
    value:
    if (isDerivation value) && (value ? text) then
      value
    else
      (
        let
          text =
            if isString value then
              value
            else if isAttrs value then
              toJSON value
            else
              throw "type error";
        in
        writeTextFile {
          name = "tmptxt";
          inherit text;
        }
      );
in
{
  lib.home = {
    patchedBinary =
      args:
      pkgs.writeShellScript "${getName args.package}-agenix-patched" # bash
        ''
          export ${args.name}=$(cat "${args.token}")
          ${getExe args.package} "$@"
        '';
    jsonUpdate =
      source: target:
      let

        script = # bash
          ''
            temp=$(mktemp)
            [ -s "${target}" ] || echo '{}' >"${target}"
            cp '${target}' "$temp"
            ${
              source
              |> mapAttrsToList (
                key: value:
                ''run ${getExe pkgs.jq} --slurpfile arg ${fileWithJson value} '${key} = $arg[0]' "$temp" | ${pkgs.moreutils}/bin/sponge "$temp" || exit''
              )
              |> concatStringsSep "\n"
            }
            mv "$temp" "${target}"
          '';
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] script;
    mkJson =
      name: raw:
      let
        text = lib.generators.toJSON { } raw;
      in
      {
        inherit raw text;
        file = pkgs.writeTextFile {
          inherit name text;
        };
      };
    gitHook =
      body:
      pkgs.writeShellScript "hook" # bash
        (
          ''
            hook_name=$(basename "$0")
            local=./.git/hooks/$hook_name
            [ -x "$local" ] && [ -f "$local" ] && {
            	exec "$local"
            }
          ''
          + body
        );
  };
}
