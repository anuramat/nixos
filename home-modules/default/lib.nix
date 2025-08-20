{
  pkgs,
  config,
  lib,
  ...
}@args:
let
  diffFile = config.xdg.stateHome + "hm-activation-diffs.txt";
  inherit (lib)
    getName
    getExe
    mapAttrsToList
    concatStringsSep
    isDerivation
    isPath
    isList
    isString
    isAttrs
    trim
    ;
  inherit (pkgs) writeTextFile;
  toJSON = lib.generators.toJSON { };

  fileWithJson =
    # @args: value: value to convert or json file derivation
    value:
    if (isDerivation value) && (value ? text) then
      value
    else
      value.__path or (writeTextFile {
        name = "tmptxt.json"; # TODO rename
        text = toJSON value;
      });

  diff =
    sourceFile: targetFile:
    trim
      # bash
      ''
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

  mkYqActivationScript =
    # @returns: activation script, that updates a YAML file (in-place)
    # note there is no diff logging compared to json version
    # @args:
    #   - target -- path of the file to update (relative to $HOME)
    #   - source -- (?list of) attribute set of key-value pairs to write, where
    #     key is the YAML path (starting with "."), and
    #     value is any/derivation
    operator: sources: target:
    let
      sourceList = if lib.isList sources then sources else [ sources ];

      calls =
        sourceList
        |> lib.concatMapStringsSep "\n" (
          lib.concatMapAttrsStringSep "\n" (
            key: value:
            let
              valueFile = fileWithJson value;
              flags = "-i -py -oy"; # in-place, yaml input, yaml output
              expr = ''select(fileIndex==0).${key} ${operator} select(fileIndex==1) | select(fileIndex==0) | ... style=""'';
              yq = getExe pkgs.yq-go;
            in
            ''run ${yq} eval-all '${expr}' ${flags} "${target}" "${valueFile}"''
          )
        );
      # TODO escape target here and in the rest of the file in similar places
      script = ''
        [ -s "${target}" ] || echo '{}' >"${target}"
        ${calls}
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] script;

  # TODO: refactor to call jq once: write all sources to a single json file, then loop in jq or at least unroll a nix loop into a jq command (still just one jq command)
  mkJqActivationScript =
    # @returns: activation script, that updates a JSON file
    # @args:
    #   - target -- path of the file to update (relative to $HOME)
    #   - source -- (?list of) attribute set of key-value pairs to write, where
    #     key is the JSON path (starting with "."), and
    #     value is any/derivation
    operator: sources: target:
    let
      sourceList = if lib.isList sources then sources else [ sources ];

      jqCalls =
        targetCopy:
        sourceList
        |> lib.concatMapStringsSep "\n" (
          lib.concatMapAttrsStringSep "\n" (
            key: value:
            let
              sourceFile = fileWithJson value;
            in
            ''run ${getExe pkgs.jq} --slurpfile arg ${sourceFile} '.${key} ${operator} $arg[0]' "${targetCopy}" | ${pkgs.moreutils}/bin/sponge "${targetCopy}" || exit''
          )
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

in

{
  lib.home = {
    inherit mkGenericActivationScript;

    agenixWrapPkg =
      pkg: vars:
      let
        agenixExport =
          vars:
          vars |> lib.mapAttrsToList (n: v: ''export ${n}=$(cat "${v.path}")'') |> concatStringsSep "\n";
        aged =
          age:
          pkgs.writeShellScriptBin "${pkg.meta.mainProgram}" # bash
            ''
              ${agenixExport (vars age.secrets)}
              ${getExe pkg} "$@"
            '';
      in
      if args ? osConfig then
        aged args.osConfig.age
      else if config ? age then
        aged config.age
      else
        pkg;

    json = {
      merge = mkJqActivationScript "*=";
      set = mkJqActivationScript "=";
    };

    yaml = {
      set = mkYqActivationScript "=";
    };

    mkJson =
      # used for configs, that share the same json values (e.g. mcp/lsp)
      # @returns: a derivation with a file containing the JSON text
      # @args:
      #   - name -- name of the file
      #   - raw -- attribute set
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

    when =
      cond: val:
      if cond then
        val
      else if isAttrs val then
        { }
      else if isString val then
        ""
      else if isList val then
        [ ]
      else
        throw "huh";

  };
}
