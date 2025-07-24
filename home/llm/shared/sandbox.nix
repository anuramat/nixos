{ pkgs, config, ... }:
let
  baseRwDirs = [
    "/tmp"
    "$PWD"
  ];
  inherit (config.lib.agents.varNames) agentName;
in
{
  lib.agents.mkSandbox =
    args:
    let
      rwDirs = map (x: ''"${x}"'') (baseRwDirs ++ args.extraRwDirs) |> builtins.concatStringsSep " ";
    in
    (pkgs.writeShellApplication {
      name = args.pname;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      # TODO add single file mode
      text = ''
        ${rwDirs}+=(${rwDirs})

        if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
          ${rwDirs}+=("$gitroot")
        fi

        XDG_DATA_HOME=$(mktemp -d)
        XDG_STATE_HOME=$(mktemp -d)
        XDG_CACHE_HOME=$(mktemp -d)
        XDG_RUNTIME_DIR=$(mktemp -d)
        ${agentName}='${args.agentName}'

        export XDG_DATA_HOME
        export XDG_STATE_HOME
        export XDG_CACHE_HOME
        export XDG_RUNTIME_DIR
        export ${agentName}

        args=()
        for i in "''${${rwDirs}[@]}"; do
        	args+=(--bind)
        	args+=("$i")
          args+=("$i")
        done

        echo "RW mounted directories:"
        printf '%s\n' "''${${rwDirs}[@]}"
        export ${rwDirs}

        bwrap --ro-bind / / --dev /dev "''${args[@]}" ${args.cmd} "$@"
      '';
    });
}
