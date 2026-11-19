{ pkgs, config, ... }:
# helper scripts for iOS shortcuts
let
  inherit (pkgs) writeShellApplication;
  inherit (config.lib.shellcheck) excludeShellChecks;

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

  mkShortcut =
    name: deps: body:
    writeShellApplication {
      inherit name excludeShellChecks;
      runtimeInputs = [
        pkgs.findutils
        pkgs.coreutils
      ]
      ++ deps;
      text = "${niriEnv}\n${body}";
    };
in
{
  home.packages = [
    (mkShortcut "open-link" [ config.programs.niri.package pkgs.firefox ] ''
      # this doesn't work because firefox isn't in path on niri:
      # browser=$(xdg-settings get default-web-browser)
      # "$(command -v gtk-launch)" "$browser" "$1"
      niri msg action spawn -- "$(command -v firefox)" "$1"
    '')
    (mkShortcut "get-clipboard" [ pkgs.wl-clipboard ] "wl-paste --no-newline 2>/dev/null || true")
    (mkShortcut "set-clipboard" [ pkgs.wl-clipboard ] "wl-copy")
  ];
}
