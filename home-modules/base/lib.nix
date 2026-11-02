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
    # @returns: activation script, that deep-merges a value into a file
    # @args:
    #   - format -- "yaml" or "toml"
    #   - source -- value to merge; it wins on conflicts, arrays are replaced
    #     whole, unmanaged keys are preserved
    #   - target -- path of the file to update
    format: source: target:
    let
      sourceFile = (pkgs.formats.${format} { }).generate "value.${format}" source;
      script =
        # bash
        ''
          target=${lib.escapeShellArg target}
          merged=$(mktemp)
          mkdir -p "$(dirname "$target")"
          touch "$target"
          # unlike `select(fileIndex == 0) * ...`, this survives an empty target
          ${getExe pkgs.yq-go} eval-all -p ${format} -o ${format} \
            '. as $item ireduce ({}; . * $item)' \
            "$target" ${sourceFile} >"$merged"

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
    inherit mkAgenixExportScript;
    json.set = mkJqActivationScript;
    yaml.set = mkYqActivationScript "yaml";
    toml.set = mkYqActivationScript "toml";
  };
}
