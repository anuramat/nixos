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
    ;
  inherit (builtins) concatStringsSep;
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
    typeFlag: dirs:
    dirs
    |> map (
      x:
      [
        typeFlag
        x
        x
      ]
      |> escapeShellArgs
    )
    |> concatStringsSep "\\\n";
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
                config.programs.go.goPath
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
            mkArgs "--bind" (baseRwDirs ++ agentDirs ++ extraRwDirs);

          tmpDirs = mkArgs "--tmpfs" [
            config.xdg.cacheHome
            config.xdg.dataHome
            config.xdg.stateHome
          ];

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
            mkArgs "--ro-bind" (
              [
                "/nix"
                "/bin"
                "/usr"
                "/etc"

                "/run/current-system"
                "/run/systemd/resolve/stub-resolv.conf"

                config.xdg.configHome
              ]
              ++ homePaths
            );

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

              bwrap \
                --die-with-parent \
                --proc /proc \
                --dev /dev \
                --tmpfs /tmp \
                \
                config.xdg.configHome \
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
