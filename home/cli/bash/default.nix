{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionVariables = {
    XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
  };
  programs.bash = {
    enable = true;
    historySize = -1;
    historyFileSize = -1;
    profileExtra = # bash
      ''
        # TODO CLEAN
        source ${./profile.sh}
        source ${./sway_autostart.sh}
      '';
    # TODO move these somewhere else?
    bashrcExtra = # bash
      ''
        source ${./xdg_shims.sh}
        [[ $- == *i* ]] || return
        for f in "${./bashrc.d}"/*; do source "$f"; done
        source ${./bashrc.sh}

        PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND;}history -a"
        source ${./osc.sh}
        source ${./history.sh}
        source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh

        export _ZO_FZF_OPTS="
        --no-sort
        --exit-0
        --select-1
        --preview='${./fzf_preview.sh} {2..}'
        "
        export _ZO_RESOLVE_SYMLINKS="1"
        export _ZO_ECHO=1
        export _ZO_EXCLUDE_DIRS="${config.xdg.cacheHome}/*:/nix/store/*"
      '';
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
