{
  # auto start on 1st tty
  programs.bash = {
    profileExtra =
      # bash
      ''
        if [[ -z $WAYLAND_DISPLAY ]] \
          && [[ $XDG_VTNR == "1" ]] \
          && command -v sway >/dev/null 2>&1; then
          if [[ -v WLR_DRM_DEVICES ]]; then
            export WLR_DRM_DEVICES=$(realpath "$WLR_DRM_DEVICES")
          fi
          exec sway
        fi
      '';
  };
}
