{ pkgs, config, ... }:
let
  baseRwDirs = [
    "/tmp"
    "$PWD"
  ];
  inherit (config.lib.agents) varNames;
in
{
  lib.agents.mkSandbox =
    args:
    let
      xdgSubdirs = map (v: "${v}/${args.xdgSubdir}") [
        config.xdg.dataHome
        config.xdg.configHome
        config.xdg.cacheHome
        config.xdg.stateHome
      ];
      rwDirs =
        map (x: ''"${x}"'') (baseRwDirs ++ xdgSubdirs ++ args.extraRwDirs) |> builtins.concatStringsSep " ";
    in
    (pkgs.writeShellApplication {
      name = args.pname;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      # TODO add single file mode
      text = ''
        ${varNames.rwDirs}+=(${rwDirs})

        if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
          ${varNames.rwDirs}+=("$gitroot")
        fi

        XDG_DATA_HOME=$(mktemp -d)
        XDG_STATE_HOME=$(mktemp -d)
        XDG_CACHE_HOME=$(mktemp -d)
        XDG_RUNTIME_DIR=$(mktemp -d)
        ${varNames.agentName}='(${args.agentName})'

        export XDG_DATA_HOME
        export XDG_STATE_HOME
        export XDG_CACHE_HOME
        export XDG_RUNTIME_DIR
        export ${varNames.agentName}

        args=()
        for i in "''${${varNames.rwDirs}[@]}"; do
        	args+=(--bind)
        	args+=("$i")
          args+=("$i")
        done

        echo "RW mounted directories:"
        printf '%s\n' "''${${varNames.rwDirs}[@]}"
        export ${varNames.rwDirs}

        bwrap --ro-bind / / --dev /dev "''${args[@]}" ${args.cmd} "$@"
      '';
    });
}
