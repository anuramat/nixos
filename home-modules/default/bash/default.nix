{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) attrValues escapeShellArgs;
  excludeShellChecks = [
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
  ];
  home =
    let
      home = config.home.homeDirectory;
      XDG_BIN_HOME = "${home}/.local/bin";
      XDG_DATA_HOME = config.xdg.dataHome;
      customXdg = {
        XDG_DOCUMENTS_DIR = "${home}/docs";
        XDG_PICTURES_DIR = "${home}/img";
        XDG_VIDEOS_DIR = "${home}/vid";
      };
    in
    {
      activation = {
        # TODO not sure if this works; feels like it doesn't on anuramat-root
        mkDirs =
          let
            dirs = attrValues customXdg;
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] "mkdir -p ${escapeShellArgs dirs}";
      };
      sessionVariables = customXdg // {
        inherit XDG_BIN_HOME;

        # TODO just in case; verify/move
        LC_ALL = "en_US.UTF-8";
        PAGER = "less";
        MANPAGER = "less";
        NIXOS_OZONE_WL = "1"; # wayland chromium/electron

        STACK_ROOT = "${config.xdg.dataHome}/stack";
        STACK_XDG = "1";

        VIRTUAL_ENV_DISABLE_PROMPT = "1"; # hide python venv prompt

        # XDG TODO move stuff here from the shims file
        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv"; # ~/.nv/

        TERMCMD = "${lib.getExe pkgs.foot}";
        # TERMCMD = "${lib.getExe pkgs.kitty} -1";
        ESCDELAY = "25";

        # TODO move this somewhere
        TODO_FILE = "/home/anuramat/notes/todo.txt";

        RUSTUP_HOME = "${XDG_DATA_HOME}/rustup";
        CARGO_HOME = "${XDG_DATA_HOME}/cargo";
      };
      sessionPath = [
        XDG_BIN_HOME
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
  lib.excludeShellChecks.numbers = excludeShellChecks; # TODO rename
  # Shellcheck configuration
  xdg.configFile."shellcheckrc".text = ''
    enable=all
    external-sources=true
  ''
  + lib.strings.concatMapStrings (v: "disable=SC${toString v}\n") excludeShellChecks;
}
