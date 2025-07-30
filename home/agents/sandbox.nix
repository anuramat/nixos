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
  shadowXdgScript =
    agentDir:
    let
      variables = [
        "XDG_CACHE_HOME"
        "XDG_DATA_HOME"
        "XDG_STATE_HOME"
      ];
      shadowWithPassthrough =
        var:
        let
          shadow = ''
            ${var}="$TEMP_ROOT/${var}"
            export ${var}
            mkdir "${"$" + var}"
          '';
          passthrough = x: ''
            agentDir="${"$" + var}/${agentDir}"
            mkdir -p "$agentDir"
            ${shadow}
            [ -a "$agentDir" ] && ln -s -T "$agentDir" "${"$" + var}/${agentDir}"
          '';
        in
        if agentDir == null then shadow else passthrough shadow;
    in
    ''
      TEMP_ROOT=$(mktemp -d)

      echo "tmp dir: $TEMP_ROOT"
      echo "shadowed paths: ${variables |> builtins.concatStringsSep ", "}"
    ''
    + (variables |> map shadowWithPassthrough |> builtins.concatStringsSep "\n");

  exportScript =
    env:
    env
    |> lib.mapAttrsToList (
      n: v: ''
        ${n}=${v}
        export ${n}
      ''
    )
    |> builtins.concatStringsSep "\n";
in
{
  lib.agents.mkSandbox =
    agent:
    let
      binName = agent.package.meta.mainProgram or agent.binName;
      args = agent.args or "";
      wrapperName = agent.wrapperName or "${binName}-sandboxed";
      extraRwDirs = agent.extraRwDirs or [ ];
      agentDir = agent.agentDir or binName; # the one in xdg directories
      agentName = agent.agentName or binName;
      cmd = "${lib.getExe' agent.package binName} ${args}";

      agentDirs =
        if agentDir != null then
          (map (v: "${v}/${agentDir}") [
            config.xdg.cacheHome
            config.xdg.configHome
            config.xdg.dataHome
            config.xdg.stateHome
          ])
        else
          [ ];
      rwDirs =
        map (x: ''"${x}"'') (baseRwDirs ++ agentDirs ++ extraRwDirs) |> builtins.concatStringsSep " ";
      env = (agent.env or { }) // {
        ${varNames.agentName} = "'${agentName}'";
      };
    in
    (pkgs.writeShellApplication {
      name = wrapperName;
      runtimeInputs = with pkgs; [
        bubblewrap
      ];

      text = ''
        # shadow some of the xdg directories with a tmp one
        ${shadowXdgScript agentDir}

        # set env variables
        ${exportScript env}

        # collect RW dirs
        ${varNames.rwDirs}+=(${rwDirs})
        if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
          # root of the current worktree, if it's not CWD already
          [[ $(realpath "$gitroot") == $(realpath "$PWD") ]] || ${varNames.rwDirs}+=("$gitroot")
          # .git/ dir
          ${varNames.rwDirs}+=("$(realpath "$(git rev-parse --git-common-dir)")") 
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
