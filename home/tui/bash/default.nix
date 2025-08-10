{
  config,
  pkgs,
  lib,
  ...
}:
let

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
      XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
      bashStateDir = config.xdg.stateHome + "/bash";
    in
    {
      activation = {
        # TODO not sure if this works; feels like it doesn't on anuramat-root
        mkDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${bashStateDir}"
        '';
      };
      sessionVariables = {
        inherit XDG_BIN_HOME;

        # TODO just in case; verify/move
        LC_ALL = "en_US.UTF-8";
        PAGER = "less";
        MANPAGER = "less";

        VIRTUAL_ENV_DISABLE_PROMPT = "1"; # hide python venv prompt

        # XDG TODO move stuff here from the shims file
        HISTFILE = bashStateDir + "/history"; # ~/.bash_history
        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv"; # ~/.nv/

        TERMCMD = "foot";
        ESCDELAY = "25";
      };
      sessionPath = [
        XDG_BIN_HOME
      ];

      shellAliases =
        let
          ezacmd = "eza --group-directories-first --group --header --git --icons=always --color=always --color-scale=all --sort=name";
        in
        {
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
    };
    less = {
      enable = true;
      keys =
        # less
        ''
          #env
          LESS = -ir
        '';
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
