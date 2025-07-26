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
      shadowXdg =
        let
          vars = [
            "XDG_DATA_HOME"
            "XDG_STATE_HOME"
            "XDG_CACHE_HOME"
            "XDG_RUNTIME_DIR"
          ];
        in
        ''
          TEMP_XDG_ROOT=$(mktemp -d)

          ${map (x: x) vars |> builtins.concatStringsSep "\n"}
          # TODO rewrite and export, maybe link agent files
          # ln -s orig/${args.xdgSubdir} tmp/${args.xdgSubdir}
        '';
    in
    (pkgs.writeShellApplication {
      name = args.pname;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      text = ''
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
