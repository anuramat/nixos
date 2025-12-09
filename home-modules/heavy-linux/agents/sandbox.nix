{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.lib.agents) varNames;
  inherit (lib)
    escapeShellArgs
    getName
    getExe
    mapAttrsToList
    concatMap
    ;

  exportScript =
    env:
    env
    |> mapAttrsToList (
      n: v: ''
        ${n}=${v}
        export ${n}
      ''
    )
    |> builtins.concatStringsSep "\n";

  mkArgs =
    {
      flag,
      paths,
      doublePath,
    }:
    let
      argsSingle =
        x:
        (
          [
            flag
            x
          ]
          ++ (if doublePath then [ x ] else [ ])
        );
    in
    paths |> concatMap argsSingle |> escapeShellArgs;
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
      agentName ? binName, # mostly for git co-authored-by
      env ? { },
      tokens ? (_: { }),
    }:
    let
      passthroughName = "${wrapperName}-unboxed";
      cmd = "${getExe package} ${escapeShellArgs args}";
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

          rwDirs =
            let
              # TODO use overlayfs instead?
              baseRwDirs = [
                config.home.sessionVariables.RUSTUP_HOME
                config.home.sessionVariables.CARGO_HOME
                config.programs.go.env.GOPATH
                "${config.home.homeDirectory}/.npm"
              ];
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
            mkArgs {
              flag = "--bind-try";
              doublePath = true;
              paths = baseRwDirs ++ agentDirs ++ extraRwDirs;
            };

          tmpDirs = mkArgs {
            flag = "--tmpfs";
            doublePath = false;
            paths = [
              config.xdg.cacheHome
              config.xdg.dataHome
              config.xdg.stateHome
            ];
          };

          roDirs =
            let
              homePaths =
                [
                  ".bashrc"
                  ".bash_profile"
                  ".profile"
                ]
                |> map (p: "${config.home.homeDirectory}/${p}");
            in
            mkArgs {
              flag = "--ro-bind-try";
              doublePath = true;
              paths = [
                "/nix"
                "/bin"
                "/usr"
                "/etc"
                "/lib"
                "/lib64"

                "/run/current-system"
                "/run/systemd/resolve/stub-resolv.conf"

                config.xdg.configHome
                config.home.sessionVariables.XDG_BIN_HOME
                config.home.sessionVariables.GHQ_ROOT
              ]
              ++ homePaths;
            };

        in
        pkgs.writeShellApplication {
          name = wrapperName;
          runtimeInputs = with pkgs; [
            bubblewrap
          ];
          text =
            scriptCommon
            +
            # bash
            ''
              PROJECT_DIRS=("$PWD")
              if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
                # root of the current worktree, if it's not CWD already
                [[ $(realpath "$gitroot") == $(realpath "$PWD") ]] || PROJECT_DIRS+=("$gitroot")
                # .git/ dir
                PROJECT_DIRS+=("$(git rev-parse --absolute-git-dir)")
              fi
              export PROJECT_DIRS
              workspaceDirs=()
              for i in "''${PROJECT_DIRS[@]}"; do
                workspaceDirs+=(--bind-try)
                workspaceDirs+=("$i")
                workspaceDirs+=("$i")
              done
              ${varNames.sandboxWrapperPath}="$0"
              export ${varNames.sandboxWrapperPath}

              [ -v TMPDIR ] || TMPDIR="/tmp"
              bwrap \
                --die-with-parent \
                --proc /proc \
                --dev /dev \
                --tmpfs /tmp \
                --tmpfs "$TMPDIR" \
                \
                ${tmpDirs} \
                ${roDirs} \
                ${rwDirs} \
                "''${workspaceDirs[@]}" \
                \
                ${cmd} "$@"
            '';
        };

    in
    pkgs.symlinkJoin {
      name = (getName package) + "-wrappers";
      paths = [
        package
      ];
      postBuild = ''
        rm -f "$out/bin/${binName}"
        ln -s ${getExe passthrough} "$out/bin/${passthroughName}"
        ln -s ${getExe sandboxed} "$out/bin/${sandboxed.name}"
      '';
    };
}
