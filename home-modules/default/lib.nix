{
  pkgs,
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  diffFile = config.xdg.stateHome + "/hm-activation-diffs.txt";
  inherit (lib)
    getExe
    concatStringsSep
    trim
    ;
  inherit (pkgs) writeTextFile;
  toJSON = lib.generators.toJSON { };

  jsonFile =
    value:
    writeTextFile {
      name = "value.json";
      text = toJSON value;
    };

  diff =
    sourceFile: targetFile:
    trim
      # bash
      ''
        mkdir -p "$(dirname "${diffFile}")"
        if [[ -s ${targetFile} ]]; then
          diff "${sourceFile}" "${targetFile}" || echo "*** ${targetFile} diff above ***"
        fi | tee -a "${diffFile}" >&2
      '';

  mkGenericActivationScript =
    sourceFile: targetFile:
    let
      script =
        # bash
        ''
          source=${lib.escapeShellArg sourceFile}
          target=${lib.escapeShellArg targetFile}
          mkdir -p "$(dirname "$target")"

          ${diff "$source" "$target"}
          run cp --no-preserve=mode "$source" "$target"
        '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  mkJqActivationScript =
    # @returns: activation script, that updates a JSON file
    # @args:
    #   - target -- path of the file to update
    #   - source -- attribute set of top-level keys to set in the target;
    #     unmanaged keys are preserved, values are any JSON-serializable value
    source: target:
    let
      script =
        # bash
        ''
          target=${lib.escapeShellArg target}
          source=$(mktemp)
          mkdir -p "$(dirname "$target")"
          { [ -s "$target" ] && cat "$target" || echo '{}'; } \
            | ${getExe pkgs.jq} --slurpfile arg ${jsonFile source} '. + $arg[0]' >"$source"

          ${diff "$source" "$target"}
          run mv "$source" "$target"
        '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  mkAgenixExportScript =
    vars:
    let
      mkScript =
        cfg:
        vars cfg.age.secrets
        |> lib.mapAttrsToList (
          name: secret: ''
            ${name}=$(<"${secret.path}")
            export ${name}
          ''
        )
        |> concatStringsSep "\n";
    in
    if osConfig != null then
      mkScript osConfig
    else if config ? age then
      mkScript config
    else
      "";

in
{
  # TODO use this everywhere
  lib.secrets = if osConfig != null then osConfig.age.secrets else config.age.secrets;
  lib.home = {
    inherit mkGenericActivationScript mkAgenixExportScript;
    json.set = mkJqActivationScript;
  };
}
