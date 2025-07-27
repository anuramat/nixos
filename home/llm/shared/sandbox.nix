{
  pkgs,
  config,
  lib,
  ...
}:
let
  baseRwDirs = [
    "/tmp"
    "$PWD"
  ];
  inherit (config.lib.agents) varNames;

  # Shadows XDG dirs with tmp, and links agent directories there
  shadowXdg =
    agentDir:
    let
      vars = [
        "XDG_CACHE_HOME"
        "XDG_DATA_HOME"
        "XDG_RUNTIME_DIR"
        "XDG_STATE_HOME"
      ];
      shadowOne = x: ''
        agentDir="${"$" + x}/${agentDir}"
        mkdir -p "$agentDir"
        ${x}="$TEMP_ROOT/${x}"; export ${x}; mkdir "${"$" + x}"
        [ -a "$agentDir" ] && ln -s -T "$agentDir" "${"$" + x}/${agentDir}"
      '';
    in
    ''
      TEMP_ROOT=$(mktemp -d)
      echo "tmp dir: $TEMP_ROOT"
    ''
    + (map shadowOne vars |> builtins.concatStringsSep "\n");
in
{
  lib.agents.mkSandbox =
    args:
    let
      binName = args.package.mainProgram;
      args = args.args or "";
      wrapperName = args.wrapperName or "${binName}-sandboxed";
      extraRwDirs = args.extraRwDirs or [ ];
      agentDir = args.agentDir or binName;
      agentName = args.agentName or binName;
      cmd = "${lib.findExe args.package} args";

      agentDirs = map (v: "${v}/${agentDir}") [
        config.xdg.cacheHome
        config.xdg.configHome
        config.xdg.dataHome
        config.xdg.stateHome
      ];
      rwDirs =
        map (x: ''"${x}"'') (baseRwDirs ++ agentDirs ++ extraRwDirs) |> builtins.concatStringsSep " ";
    in
    (pkgs.writeShellApplication {
      name = wrapperName;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      text = ''
        # shadow some of the xdg directories with a tmp one
        ${shadowXdg agentDir}

        # set agent
        ${varNames.agentName}='${agentName}'
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

        bwrap --ro-bind / / --dev /dev "''${args[@]}" ${cmd} "$@"
      '';
    });
}
