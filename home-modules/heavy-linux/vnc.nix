# `vnc HOST`: view the desktop of HOST, through a wayvnc started over ssh
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "vnc";
      runtimeInputs = [ pkgs.wlvncc ];
      text = ''
        # forced pty: killing ssh hangs up the remote wayvnc
        ssh -tt -o ExitOnForwardFailure=yes -L 5900:127.0.0.1:5900 "''${1:?usage: vnc HOST}" \
          WAYLAND_DISPLAY=/run/user/1000/wayland-1 wayvnc 127.0.0.1 5900 &
        ssh=$!
        trap 'kill $ssh 2>/dev/null' EXIT
        # the tunnel accepts connections before wayvnc listens; wait for its greeting
        until [ "$(head -c3 2>/dev/null </dev/tcp/127.0.0.1/5900)" = RFB ]; do
          kill -0 $ssh 2>/dev/null
          sleep 0.5
        done
        wlvncc 127.0.0.1 5900
      '';
    })
  ];
}
