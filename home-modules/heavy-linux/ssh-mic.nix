# Exposes the mic of the machine we ssh'd from as the default pipewire source,
# backed by the pulse socket forwarded via RemoteForward (see default hm module).
{ pkgs, lib, ... }:
let
  tunnel = pkgs.writeShellApplication {
    name = "ssh-mic-tunnel";
    runtimeInputs = with pkgs; [
      pulseaudio
      coreutils
    ];
    text = ''
      sock="''${XDG_RUNTIME_DIR:-/run/user/$UID}/pulse-ssh.sock"
      id=$(pactl load-module module-tunnel-source "server=unix:$sock" source_name=ssh-mic)
      trap 'pactl unload-module "$id"' EXIT
      pactl set-default-source ssh-mic
      # exit (unloading the module) when the socket disappears or is replaced
      # by a new ssh session; the path unit then retriggers against the new one
      ino=$(stat -c %i "$sock")
      while [ "$(stat -c %i "$sock" 2>/dev/null)" = "$ino" ]; do sleep 2; done
    '';
  };
in
{
  systemd.user = {
    services.ssh-mic = {
      Unit.Description = "Tunnel source backed by the ssh-forwarded pulse socket";
      Service.ExecStart = lib.getExe tunnel;
    };
    paths.ssh-mic = {
      Path.PathExists = "%t/pulse-ssh.sock";
      Install.WantedBy = [ "paths.target" ];
    };
  };
}
