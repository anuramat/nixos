{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) attrValues escapeShellArgs;
  shellcheckExcludes = [
    2016 # expansion in '' won't work
    2059 # don't use variables in printf format string
    2292 # prefer [[]] over []
    2139 # unintended? expansion in an alias (alias a="$test" instead of '$test')
    2250 # use braces even if not necessary
    1003 # trying to escape a single quote?
    2312 # return value is masked by $()
    2154 # referenced but not assigned, e.g. $XDG_CONFIG_HOME
  ];
in
{
  imports = [
    ./bashrc.nix
    ./template.nix
  ];
  home =
    let
      home = config.home.homeDirectory;
      XDG_BIN_HOME = "${home}/.local/bin";
      XDG_DATA_HOME = config.xdg.dataHome;
      CARGO_HOME = "${XDG_DATA_HOME}/cargo";
      customXdg = {
        XDG_DOCUMENTS_DIR = "${home}/docs";
        XDG_PICTURES_DIR = "${home}/img";
        XDG_VIDEOS_DIR = "${home}/vid";
      };
    in
    {
      activation = {
        mkDirs =
          let
            dirs = attrValues customXdg;
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] "mkdir -p ${escapeShellArgs dirs}";
      };
      sessionVariables = customXdg // {
        inherit XDG_BIN_HOME CARGO_HOME;

        # TODO just in case; verify/move
        LC_ALL = inputs.self.user.locale;
        PAGER = "less";
        MANPAGER = "less";

        STACK_ROOT = "${config.xdg.dataHome}/stack";
        STACK_XDG = "1";

        NODE_REPL_HISTORY = "${XDG_DATA_HOME}/node_repl_history";
        DOT_SAGE = "${config.xdg.configHome}/sage"; # sage math
        DVDCSS_CACHE = "${XDG_DATA_HOME}/dvdcss"; # VLC dependency
        MPLAYER_HOME = "${config.xdg.configHome}/mplayer"; # unused but ends up in $HOME otherwise

        VIRTUAL_ENV_DISABLE_PROMPT = "1"; # hide python venv prompt

        ESCDELAY = "25";

        # TODO move this somewhere
        TODO_FILE = "${config.home.homeDirectory}/notes/todo.txt";

        RUSTUP_HOME = "${XDG_DATA_HOME}/rustup";
      };
      sessionPath = [
        XDG_BIN_HOME
        "${CARGO_HOME}/bin"
      ];

      shellAliases =
        let
          ezacmd = "eza --group-directories-first --group --header --git --icons=always --color=always --color-scale=all --sort=name";
        in
        {
          mitmproxy = "mitmproxy --set confdir=$XDG_CONFIG_HOME/mitmproxy";
          mitmweb = "mitmweb --set confdir=$XDG_CONFIG_HOME/mitmproxy";

          ls = "${ezacmd}";
          ll = "${ezacmd} --long";
          la = "${ezacmd} --long --all";
          tree = "${ezacmd} --tree";
          treedir = "${ezacmd} --tree --only-dirs";

          f = "nvim";
          z = "zellij attach --create";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          peco = "fzf --height=100 --preview=";

          diff = "diff --color=auto";
          grep = "grep --color=auto";
          ip = "ip -c=auto";
        };
    };

  programs = {
    bash = {
      enable = true;
      historySize = -1;
      historyFileSize = -1;
      historyFile = config.xdg.stateHome + "/bash/history";
      historyIgnore = [
        "la"
        "f"
        "git st"
        "j nixos"
        "up"
        "y"
        "m"
        "j"
        "just"
        "ls"
      ];
      historyControl = [
        "ignoreboth"
        "erasedups"
      ];
    };
    less = {
      enable = true;
    };
    starship = {
      enable = true;
      settings = {
        format = " $username$hostname$directory$git_branch$git_state$git_status$cmd_duration$time$shlvl$line_break $character";

        directory.style = "blue";

        character = {
          success_symbol = "[\\$](purple)";
          error_symbol = "[\\$](red)";
          vimcmd_symbol = "[\\$](green)";
        };

        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };

        git_status = {
          format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
          style = "cyan";
          conflicted = "​";
          untracked = "​";
          modified = "​";
          staged = "​";
          renamed = "​";
          deleted = "​";
          stashed = "≡";
        };

        git_state = {
          format = "\([$state( $progress_current/$progress_total)]($style)\) ";
          style = "bright-black";
        };

        cmd_duration = {
          format = "[$duration]($style) ";
          style = "yellow";
        };

        time = {
          disabled = false;
        };
        shlvl = {
          disabled = false;
        };
      };
    };
  };
  lib.shellcheck.excludes = shellcheckExcludes;
  # Shellcheck configuration
  xdg.configFile."shellcheckrc".text = ''
    enable=all
    external-sources=true
  ''
  + lib.strings.concatMapStrings (v: "disable=SC${toString v}\n") shellcheckExcludes;
}
