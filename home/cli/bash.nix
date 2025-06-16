{
  programs.bash = {
    enable = true;
    profileExtra = # bash
      ''
        source ${./files/sway_autostart.sh}
      '';
    # TODO transfer as much as possible from ./files to options
    # TODO move these somewhere else?
    bashrcExtra = # bash
      ''
        source ${./files/xdg_shims.sh}
        [[ $- == *i* ]] || return
        for f in "${./files/bashrc.d}"/*; do source "$f"; done
        source ${./files/bashrc.sh}

        export _ZO_FZF_OPTS="
        --no-sort
        --exit-0
        --select-1
        --preview='${./files/fzf_preview.sh} {2..}'
        "
        export _ZO_RESOLVE_SYMLINKS="1"
        export _ZO_ECHO=1
        export _ZO_EXCLUDE_DIRS="${config.xdg.cacheHome}/*:/nix/store/*"
      '';
  };
}
