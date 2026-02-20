let
  wm = "niri-session";
in
{
  # auto start on 1st tty
  programs.bash = {
    profileExtra =
      # bash
      ''
        	if [[ -z $WAYLAND_DISPLAY ]] \
        	  && [[ -z $WM_STARTED ]] \
        	  && [[ $XDG_VTNR == "1" ]] \
        	  && command -v ${wm} >/dev/null 2>&1; then
        	  export WM_STARTED
        	  WM_STARTED=1
        	  if [[ -v WLR_DRM_DEVICES ]]; then
        	    export WLR_DRM_DEVICES=$(realpath "$WLR_DRM_DEVICES")
        	  fi
        	  exec ${wm}
        	fi
      '';
  };
}
