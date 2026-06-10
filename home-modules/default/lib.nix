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
          source=${sourceFile}
          target=${targetFile}
          mkdir -p "$(dirname "$target")"

          ${diff "$source" "$target"}
          run cat "$source" >"$target"
        '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  # TODO: refactor to call jq once: write all sources to a single json file, then loop in jq or at least unroll a nix loop into a jq command (still just one jq command)
  mkJqActivationScript =
    # @returns: activation script, that updates a JSON file
    # @args:
    #   - target -- path of the file to update (relative to $HOME)
    #   - source -- attribute set of key-value pairs to write, where
    #     key is the JSON path, and value is any JSON-serializable value
    source: target:
    let
      jqCalls =
        targetCopy:
        source
        |> lib.concatMapAttrsStringSep "\n" (
          key: value:
          ''run ${getExe pkgs.jq} --slurpfile arg ${jsonFile value} '.${key} = $arg[0]' "${targetCopy}" | ${pkgs.moreutils}/bin/sponge "${targetCopy}" || exit''
        );

      script = ''
        target=${target}
        source=$(mktemp)
        mkdir -p "$(dirname "$target")"
        [ -s "$target" ] || echo '{}' >"$target"

        cp "$target" "$source"
        ${jqCalls "$source"}

        ${diff "$source" "$target"}
        mv "$source" "$target"
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
