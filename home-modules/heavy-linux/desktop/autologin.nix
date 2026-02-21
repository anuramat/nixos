{ pkgs, ... }:
let
  niri = pkgs.writeShellScript "niri" ''
    if systemctl --user -q is-active niri.service; then
      echo 'A niri session is already running.'
      exit 1
    fi

    systemctl --user reset-failed
    # systemctl --user import-environment
    dbus-update-activation-environment --all --systemd
    systemctl --user unset-environment SHLVL
    systemctl --user --wait start niri.service
    systemctl --user start --job-mode=replace-irreversibly niri-shutdown.target
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
  '';

  wm = niri;
in
{
  # auto start on 1st tty
  programs.bash = {
    profileExtra =
      # bash
      ''
        	if [[ -z $WAYLAND_DISPLAY ]] \
        	  && [[ $XDG_VTNR == "1" ]] \
        	  && command -v ${wm} >/dev/null 2>&1; then
        	  if [[ -v WLR_DRM_DEVICES ]]; then
        	    export WLR_DRM_DEVICES=$(realpath "$WLR_DRM_DEVICES")
        	  fi
        	  exec ${wm}
        	fi
      '';
  };
}
