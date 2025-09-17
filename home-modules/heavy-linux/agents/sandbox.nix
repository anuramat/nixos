{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.lib.agents) varNames;
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
  lib.agents.mkPackages =
    {
      package,
      binName ? package.meta.mainProgram,
      args ? "", # TODO use escape helper from lib and switch this to list
      passthroughName ? binName,
      wrapperName ? "${binName}-sandboxed",
      extraRwDirs ? [ ],
      agentDir, # name of subdir in xdg dirs
      agentName ? binName,
      env ? { },
      tokens ? (f: { }),
    }:
    let
      cmd = "${lib.getExe package} ${args}"; # TODO unfuck this
      scriptCommon =
        let
          defaultEnv = {
            ${varNames.agentName} = "'${agentName}'";
          };
        in
        # bash
        ''
          unset GIT_EXTERNAL_DIFF
          ${config.lib.home.mkAgenixExportScript tokens}
          ${exportScript (env // defaultEnv)}
        '';
      passthrough = pkgs.writeShellApplication {
        name = passthroughName;
        text =
          scriptCommon
          +
          # bash
          ''
            ${cmd} "$@"
          '';
      };

      sandboxed =
        let
          rwDirs =
            let
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
            in
            map (x: ''"${x}"'') (baseRwDirs ++ agentDirs ++ extraRwDirs) |> builtins.concatStringsSep " ";

          gopath = "${config.home.homeDirectory}/go";
          baseRwDirs = [
            "/tmp"
            "$PWD"
            "$XDG_RUNTIME_DIR"
            config.home.sessionVariables.RUSTUP_HOME
            config.home.sessionVariables.CARGO_HOME
            # TODO wipe these
            "${config.home.homeDirectory}/.npm"
            gopath
          ];

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

        in
        (pkgs.writeShellApplication {
          name = wrapperName;
          runtimeInputs = with pkgs; [
            bubblewrap
          ];

          text =
            scriptCommon
            +
            # bash
            ''
              # shadow some of the xdg directories with a tmp one
              ${shadowXdgScript agentDir}

              # collect RW dirs for bwrap
              ${varNames.rwDirs}+=(${rwDirs})
              if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
                # root of the current worktree, if it's not CWD already
                [[ $(realpath "$gitroot") == $(realpath "$PWD") ]] || ${varNames.rwDirs}+=("$gitroot")
                # .git/ dir
                ${varNames.rwDirs}+=("$(realpath "$(git rev-parse --git-common-dir)")") 
              fi
              export ${varNames.rwDirs}
              echo "RW mounted directories:" && printf '\t%s\n' "''${${varNames.rwDirs}[@]}"

              # build bwrap args
              args=()
              for i in "''${${varNames.rwDirs}[@]}"; do
                mkdir -p "$i"
              	args+=(--bind-try)
              	args+=("$i")
                args+=("$i")
              done

              bwrap --ro-bind / / --dev /dev "''${args[@]}" ${cmd} "$@"
            '';
        });
    in
    pkgs.symlinkJoin {
      name = (lib.getName package) + "-wrappers";
      paths = [
        package
      ];
      postBuild = ''
        rm -f "$out/bin/${binName}"
        ln -s ${lib.getExe passthrough} "$out/bin/${passthroughName}"
        ln -s ${lib.getExe sandboxed} "$out/bin/${sandboxed.name}"
      '';
    };
}
