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
      wrapperName ? binName,
      args ? [ ],
      extraRwDirs ? [ ],
      agentDir, # name of subdir in xdg dirs
      agentName ? binName,
      env ? { },
      tokens ? (f: { }),
    }:
    let
      passthroughName = "${wrapperName}-unboxed";
      cmd = "${lib.getExe package} ${lib.escapeShellArgs args}";
      # TODO rename -- reflect that it's a preamble
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
          # XXX make more robust somehow? but then $PWD won't expand
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
                  shadow = # bash
                    ''
                      ${var}="$TEMP_ROOT/${var}"
                      export ${var}
                      mkdir "${"$" + var}"
                    '';
                  passthrough =
                    x: # bash
                    ''
                      agentDir="${"$" + var}/${agentDir}"
                      mkdir -p "$agentDir"
                      ${shadow}
                      [ -a "$agentDir" ] && ln -s -T "$agentDir" "${"$" + var}/${agentDir}"
                    '';
                in
                if agentDir == null then shadow else passthrough shadow;
              header =
                # bash
                ''
                  TEMP_ROOT=$(mktemp -d)
                  # TODO make a helper for this
                  ${varNames.agentSandboxLog}+="tmp dir: $TEMP_ROOT"$'\n'"shadowed vars: ${
                    variables |> builtins.concatStringsSep ", "
                  }"$'\n'
                '';
            in
            header + (variables |> map shadowWithPassthrough |> builtins.concatStringsSep "\n");

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
              ${varNames.agentSandboxLogFile}="${config.xdg.cacheHome}/agents.log"
              ${varNames.agentSandboxLog}="launching ${agentName} in $PWD: $(date '+%Y-%m-%d %H:%M:%S %z')"

              # shadow some of the xdg directories with a tmp one
              ${shadowXdgScript agentDir}

              # collect RW dirs for bwrap
              RW_DIRS+=(${rwDirs})
              if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
                # root of the current worktree, if it's not CWD already
                [[ $(realpath "$gitroot") == $(realpath "$PWD") ]] || RW_DIRS+=("$gitroot")
                # .git/ dir
                RW_DIRS+=("$(realpath "$(git rev-parse --git-common-dir)")") 
              fi

              ${varNames.agentSandboxLog}+=$(echo "RW dirs:" && printf '\t%s\n' "''${RW_DIRS[@]}")

              # build bwrap args
              args=()
              for i in "''${RW_DIRS[@]}"; do
                mkdir -p "$i"
              	args+=(--bind-try)
              	args+=("$i")
                args+=("$i")
              done

              echo "''$${varNames.agentSandboxLog}"$'\n' >> "''$${varNames.agentSandboxLogFile}"
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
