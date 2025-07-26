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
      shadowXdg =
        let
          vars = [
            "XDG_CACHE_HOME"
            "XDG_DATA_HOME"
            "XDG_RUNTIME_DIR"
            "XDG_STATE_HOME"
          ];
        in
        ''
          TEMP_XDG_ROOT=$(mktemp -d)
          echo "tmp dir: $TEMP_XDG_ROOT"
          ${
            map (
              x:
              let
                shadow = ''${x}="$TEMP_XDG_ROOT/${x}"; export ${x}; mkdir "${"$" + x}"'';
              in
              if args ? xdgSubdir then
                ''
                  agentDir="${"$" + x}/${args.xdgSubdir}"
                  ${shadow}
                  [ -a "$agentDir" ] && ln -s -T "$agentDir" "${"$" + x}/${args.xdgSubdir}"
                ''
              else
                shadow
            ) vars
            |> builtins.concatStringsSep "\n"
          }
        '';
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
        ${shadowXdg}

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
