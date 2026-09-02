# Exposes the mic of the machine we ssh'd from as the default pipewire source,
# backed by the pulse socket forwarded via RemoteForward below.
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
      # the socket may be stale (dead listener) until the next ssh connection
      # replaces it; retry instead of dying and tripping the start limit
      until id=$(pactl load-module module-tunnel-source "server=unix:$sock" source_name=ssh-mic); do
        [ -S "$sock" ] || exit 0
        sleep 2
      done
      trap 'pactl unload-module "$id"' EXIT
      # the tunnel source appears asynchronously after the module loads
      until pactl set-default-source ssh-mic; do
        [ -S "$sock" ] || exit 0
        sleep 1
      done
      # exit (unloading the module) when the socket disappears or is replaced
      # by a new ssh session; the path unit then retriggers against the new one
      ino=$(stat -c %i "$sock")
      while [ "$(stat -c %i "$sock" 2>/dev/null)" = "$ino" ]; do sleep 2; done
    '';
  };
in
{
  # expose local pulse socket to bgm5 (mic for voice input etc); `final` so it
  # also matches when connecting through the `bgm5` alias
  programs.ssh.settings."Match final host anuramat-bgm5".RemoteForward =
    "/run/user/%i/pulse-ssh.sock /run/user/%i/pulse/native";

  systemd.user = {
    services.ssh-mic = {
      Unit = {
        Description = "Tunnel source backed by the ssh-forwarded pulse socket";
        # the script paces itself; a failure cascade must not kill the path unit
        StartLimitIntervalSec = 0;
      };
      Service.ExecStart = lib.getExe tunnel;
    };
    paths.ssh-mic = {
      Path.PathExists = "%t/pulse-ssh.sock";
      Install.WantedBy = [ "paths.target" ];
    };
  };
}
