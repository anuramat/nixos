# TODO rename file
{ lib, ... }:
with lib;
with builtins;
rec {
  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");
  getSchema = attrsets.mapAttrsRecursive (path: v: typeOf v);
  join = s: with lib; s |> splitString "\n" |> concatStringsSep " ";
  getMatches =
    patterns: x:
    mapAttrs (
      name: schema: if typeOf x == "set" then schema == getSchema x else schema == typeOf x
    ) patterns;
  # TODO maybe move
  pythonConfig =
    root: cfg:
    let
      formatValue =
        v:
        if builtins.isBool v then
          (if v then "True" else "False")
        else if builtins.isString v then
          ''"${v}"''
        else
          toString v;
      formatAssignment =
        prefix: name: value:
        if builtins.isAttrs value then
          lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment "${prefix}.${name}") value)
        else
          "${prefix}.${name} = ${formatValue value}";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment root) cfg);
  gitHook =
    pkgs: main:
    pkgs.writeShellScript "hook" # bash
      (
        ''
          hook_name=$(basename "$0")
          local=./.git/hooks/$hook_name
          [ -x "$local" ] && [ -f "$local" ] && {
          	exec "$local"
          }
        ''
        + main
      );

  # TODO look at usage and improve ux
  jsonUpdate =
    pkgs: target: argsList: # bash
    ''
      temp=$(mktemp)
      [ -s "${target}" ] || echo '{}' > "${target}"
      cp '${target}' "$temp"
      ${
        argsList
        |> map (
          args:
          let
            source =
              # TODO assert that only one is present
              args.file or (pkgs.writeTextFile {
                name = "jq_piece";
                inherit (args) text;
              });
          in
          ''run ${getExe pkgs.jq} --slurpfile arg ${source} '${args.prop} = $arg[0]' "$temp" | ${pkgs.moreutils}/bin/sponge "$temp" || exit''
        )
        |> lib.concatStringsSep "\n"
      }
      mv "$temp" "${target}"
    '';

  patchedBinary =
    pkgs: args:
    pkgs.writeShellScript "${getName args.package}-agenix-patched" # bash
      ''
        export ${args.name}=$(cat "${args.token}")
        ${getExe args.package} "$@"
      '';
}
