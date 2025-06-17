{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    historySize = -1;
    historyFileSize = -1;
    profileExtra = # bash
      ''
        source ${./sway_autostart.sh}
      '';
    # TODO transfer as much as possible from ./files to options
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
}
