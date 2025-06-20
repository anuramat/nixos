{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./bashrc.nix
  ];
  home =
    let
      XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
    in
    {
      sessionVariables = {
        inherit XDG_BIN_HOME;

        # TODO just in case; verify/move
        LC_ALL = "en_US.UTF-8";
        PAGER = "less";
        MANPAGER = "less";

        VIRTUAL_ENV_DISABLE_PROMPT = "1"; # hide python venv prompt

        # XDG TODO move stuff here from the shims file
        HISTFILE = "${config.xdg.stateHome}/bash/history"; # ~/.bash_history
        CUDA_CACHE_PATH = "${config.xdg.stateHome}/nv"; # ~/.nv/
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

  # Shellcheck configuration
  xdg.configFile."shellcheckrc".text =
    ''
      enable=all
      external-sources=true
    ''
    + lib.strings.concatMapStrings (p: "disable=${p}\n") [
      "SC1003" # incorrect attempt at escaping a single quote?
      "SC1090" # can't follow non constant source
      "SC2015" # A && B || C is not an if-then-else
      "SC2016" # incorrect attempt at expansion?
      "SC2059" # don't use variables in printf format string
      "SC2139" # unintended? expansion in an alias (alias a="$test" instead of '$test')
      "SC2154" # variable referenced but not assigned
      "SC2155" # "local" masks return values
      "SC2250" # quote even if not necessary
      "SC2292" # prefer [[]] over
      "SC2312" # this masks return value
    ];
}
