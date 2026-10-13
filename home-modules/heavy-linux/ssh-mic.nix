# SLOP
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
      ino=$(stat -c %i "$sock" 2>/dev/null) || exit 0
      # the socket may be dead: sshd leaves it behind when the session ends,
      # and a session whose client went away keeps accepting connections that
      # never reach it; so probe it first, and on any failure fall through to
      # waiting for the next session instead of retrying, or exiting, which
      # would retrigger the path unit in a tight loop
      if timeout 5 pactl --server="unix:$sock" info >/dev/null 2>&1 &&
        id=$(pactl load-module module-tunnel-source "server=unix:$sock" source_name=ssh-mic); then
        trap 'pactl unload-module "$id" 2>/dev/null' EXIT
        # the tunnel source appears asynchronously after the module loads, if
        # at all: the module drops itself when it fails to connect
        for _ in {1..10}; do
          pactl set-default-source ssh-mic 2>/dev/null && break
          sleep 1
        done
      fi
      # exit (unloading the module) when the socket disappears or is replaced
      # by a new ssh session; the path unit then retriggers against the new one
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
