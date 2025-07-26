{ pkgs, config, ... }:
let
  baseRwDirs = [
    "/tmp"
    "$PWD"
  ];
  inherit (config.lib.agents) varNames;
  shadowXdg =
    passthrough:
    let
      vars = [
        "XDG_CACHE_HOME"
        "XDG_DATA_HOME"
        "XDG_RUNTIME_DIR"
        "XDG_STATE_HOME"
      ];
      shadowOne =
        x:
        let
          shadow = ''${x}="$TEMP_ROOT/${x}"; export ${x}; mkdir "${"$" + x}"'';
        in
        if passthrough != null then
          ''
            agentDir="${"$" + x}/${passthrough}"
            ${shadow}
            [ -a "$agentDir" ] && ln -s -T "$agentDir" "${"$" + x}/${passthrough}"
          ''
        else
          shadow;
    in
    ''
      TEMP_ROOT=$(mktemp -d)
      echo "tmp dir: $TEMP_ROOT"

      ${map shadowOne vars |> builtins.concatStringsSep "\n"}
    '';
in
{
  lib.agents.mkSandbox =
    args:
    let
      agentDirs =
        if !args ? xdgSubdir then
          [ ]
        else
          (map (v: "${v}/${args.xdgSubdir}") [
            config.xdg.cacheHome
            config.xdg.configHome
            config.xdg.dataHome
            config.xdg.stateHome
          ]);
      rwDirs =
        map (x: ''"${x}"'') (baseRwDirs ++ agentDirs ++ (args.extraRwDirs or [ ]))
        |> builtins.concatStringsSep " ";
    in
    (pkgs.writeShellApplication {
      name = args.pname;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      text = ''
        # shadow some of the xdg directories with a tmp one
        ${shadowXdg (args.xdgSubdir or null)}

        # set agent
        ${varNames.agentName}='${args.agentName}'
        export ${varNames.agentName}

        # collect RW dirs
        ${varNames.rwDirs}+=(${rwDirs})
        if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
          ${varNames.rwDirs}+=("$gitroot")
        fi
        export ${varNames.rwDirs}
        echo "RW mounted directories:" && printf '\t%s\n' "''${${varNames.rwDirs}[@]}"

        # build args
        args=()
        for i in "''${${varNames.rwDirs}[@]}"; do
        	args+=(--bind)
        	args+=("$i")
          args+=("$i")
        done

        bwrap --ro-bind / / --dev /dev "''${args[@]}" ${args.cmd} "$@"
      '';
    });
}
