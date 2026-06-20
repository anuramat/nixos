{ pkgs, config, ... }:
# helper scripts for iOS shortcuts
let
  inherit (pkgs) writeShellApplication;
  excludeShellChecks = map (v: "SC" + toString v) config.lib.shellcheck.excludes;

  niriEnv = # bash
    ''
      mapfile -d "" -t sockets < <(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'niri.wayland*.sock' -print0)
      if [[ ''${#sockets[@]} -ne 1 ]]; then
        echo "expected exactly one socket, found ''${#sockets[@]}" >&2
        exit 1
      fi
      NIRI_SOCKET=''${sockets[0]}
      WAYLAND_DISPLAY=$(basename "$NIRI_SOCKET" | cut -d . -f 2)
      export NIRI_SOCKET WAYLAND_DISPLAY
    '';

in
{
  home.packages = [
    (writeShellApplication {
      name = "open-link";
      inherit excludeShellChecks;
      runtimeInputs = [
        pkgs.findutils
        pkgs.niri
        pkgs.firefox
      ];
      text = ''
        ${niriEnv}

        # this doesn't work because firefox isn't in path on niri:
        # browser=$(xdg-settings get default-web-browser)
        # "$(command -v gtk-launch)" "$browser" "$1"
        niri msg action spawn -- "$(command -v firefox)" "$1"
      '';
    })
    (writeShellApplication {
      name = "get-clipboard";
      inherit excludeShellChecks;
      runtimeInputs = [
        pkgs.findutils
        pkgs.coreutils
        pkgs.wl-clipboard
      ];
      text = ''
        ${niriEnv}

        wl-paste --no-newline 2>/dev/null || true
      '';
    })
    (writeShellApplication {
      name = "set-clipboard";
      inherit excludeShellChecks;
      runtimeInputs = [
        pkgs.findutils
        pkgs.coreutils
        pkgs.wl-clipboard
      ];
      text = ''
        ${niriEnv}

        wl-copy
      '';
    })
  ];
}
