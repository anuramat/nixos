{
  pkgs,
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  inherit (lib)
    getExe
    concatStringsSep
    ;
  inherit (pkgs) writeTextFile;
  toJSON = lib.generators.toJSON { };

  jsonFile =
    value:
    writeTextFile {
      name = "value.json";
      text = toJSON value;
    };

  yamlFile =
    value:
    writeTextFile {
      name = "value.yaml";
      text = lib.generators.toYAML { } value;
    };

  mkGenericActivationScript =
    sourceFile: targetFile:
    let
      script =
        # bash
        ''
          source=${lib.escapeShellArg sourceFile}
          target=${lib.escapeShellArg targetFile}
          mkdir -p "$(dirname "$target")"

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

          run mv "$source" "$target"
        '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  mkYqActivationScript =
    source: target:
    let
      script =
        # bash
        ''
          target=${lib.escapeShellArg target}
          current=$(mktemp)
          merged=$(mktemp)
          mkdir -p "$(dirname "$target")"
          { [ -s "$target" ] && cat "$target" || echo '{}'; } >"$current"
          ${getExe pkgs.yq-go} eval-all \
            'select(fileIndex == 0) * select(fileIndex == 1)' \
            "$current" ${yamlFile source} >"$merged"
          rm "$current"

          run mv "$merged" "$target"
        '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  secrets = if osConfig != null then osConfig.age.secrets else config.age.secrets;

  mkAgenixExportScript =
    vars:
    vars secrets
    |> lib.mapAttrsToList (
      name: secret: ''
        ${name}=$(<"${secret.path}")
        export ${name}
      ''
    )
    |> concatStringsSep "\n";

in
{
  lib.secrets = secrets;
  lib.home = {
    inherit mkGenericActivationScript mkAgenixExportScript;
    json.set = mkJqActivationScript;
    yaml.set = mkYqActivationScript;
  };
}
