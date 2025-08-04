{
  pkgs,
  config,
  lib,
  ...
}:
let
  difffile = config.xdg.stateHome + "hm-activation-diffs.txt";
  inherit (lib)
    getName
    getExe
    mapAttrsToList
    concatStringsSep
    isDerivation
    isPath
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
          echo START DIFF "${targetFile}"
          diff "${sourceFile}" "${targetFile}"
          echo END DIFF
        fi | tee -a "${difffile}" >&2
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
      script = # bash
        ''
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

    patchedBinary =
      # returns a patched binary that sets an environment variable
      # TODO rename to agenixPatchedBinary or something
      args:
      pkgs.writeShellScript "${getName args.package}-agenix-patched" # bash
        ''
          export ${args.name}=$(cat "${args.token}")
          ${getExe args.package} "$@"
        '';

    json = {
      merge = mkJqActivationScript "*=";
      set = mkJqActivationScript "=";
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

  };
}
