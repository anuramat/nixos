{
  lib,
  config,
  pkgs,
  ...
}:
let
  # TODO parameterize or smth
  bookdir = "${config.home.homeDirectory}/books";

  inherit (lib) escapeShellArg getExe getExe';

  noctaliaMsg =
    let
      bin = getExe config.programs.noctalia.package;
    in
    cmd:
    [
      bin
      "msg"
    ]
    ++ cmd;

  ctl = {
    brightness = {
      up = noctaliaMsg [ "brightness-up" ];
      down = noctaliaMsg [ "brightness-down" ];
    };
    sound = {
      up = noctaliaMsg [ "volume-up" ];
      down = noctaliaMsg [ "volume-down" ];
      mute = noctaliaMsg [ "volume-mute" ];
      muteMic = noctaliaMsg [ "mic-mute" ];
    };
    playback = {
      prev = noctaliaMsg [
        "media"
        "previous"
      ];
      next = noctaliaMsg [
        "media"
        "next"
      ];
      playPause = noctaliaMsg [
        "media"
        "toggle"
      ];
      stop = noctaliaMsg [
        "media"
        "stop"
      ];
    };
    bluetooth = [
      (getExe' pkgs.tlp "bluetooth")
      "toggle"
    ];
    lock = noctaliaMsg [
      "session"
      "lock"
    ];
    sleep = [
      "systemctl"
      "suspend"
    ];
    wlan = [
      (getExe' pkgs.tlp "wifi")
      "toggle"
    ];
  };

  # +new-window asks the background instance over D-Bus instead of starting a full ghostty process
  term = [
    config.home.sessionVariables.TERMCMD
    "+new-window"
  ];

  # SLOP
  # launcher dmenu entries, keyed by prefix; keys open the launcher on them
  menus =
    let
      # {selection}/{query} are pasted verbatim into a `sh -lc` string, so read
      # them through a quoted heredoc instead of relying on shell quoting
      heredoc = tok: "$(cat <<'EOF'\n${tok}\nEOF\n)";
      todo = "TODO_FILE=${escapeShellArg config.programs.todo.file} ${getExe pkgs.todo}";
    in
    {
      todo = {
        label = "Add task";
        freeform = true;
        exec = "${todo} add \"${heredoc "{query}"}\"";
      };
      done = {
        label = "Complete task";
        command = "${todo} ls | tac";
        exec = "set -- ${heredoc "{selection}"}; ${todo} rm \"$1\"";
      };
      book = {
        label = "Read book";
        command = "${getExe pkgs.fd} -t f --base-directory ${bookdir}";
        exec = "cd ${bookdir} && ${getExe pkgs.zathura} \"${heredoc "{selection}"}\"";
      };
    };

  openMenu =
    prefix:
    noctaliaMsg [
      "panel-toggle"
      "launcher"
      "/${prefix} "
    ];

  mkGlobal = x: {
    allow-when-locked = true;
    action.spawn = x;
  };

  record =
    let
      dir = "${config.home.sessionVariables.XDG_VIDEOS_DIR}/screen";
      bin = getExe pkgs.gpu-screen-recorder;
      pkill = getExe' pkgs.procps "pkill";
    in
    pkgs.writeShellScript "record" ''
      if ! ${pkill} -INT -x gpu-screen-reco; then
        mkdir -p ${dir}
        ${bin} -w screen -o "${dir}/$(date +%Y-%m-%d_%H-%M-%S).mp4"
      fi
    '';

in

{
  programs.noctalia.settings.shell.launcher.dmenu.entry = lib.mapAttrs (
    prefix: entry: entry // { inherit prefix; }
  ) menus;

  programs.niri.settings.binds = {
    "Mod+semicolon".action.spawn = term;
    "Mod+Q" = {
      action."close-window" = { };
      repeat = false;
    };

    "Mod+Space".action.spawn = noctaliaMsg [
      "panel-toggle"
      "launcher"
    ];
    "Mod+A".action.spawn = openMenu "todo";
    "Mod+Ctrl+A".action.spawn = openMenu "done";
    "Mod+B".action.spawn = openMenu "book";

    "Ctrl+Alt+Space".action.switch-layout = "next";

    "Mod+Tab".action.focus-monitor-next = { };
    "Mod+Ctrl+Tab".action.move-window-to-monitor-next = { };
    "Mod+Shift+Tab".action.move-column-to-monitor-next = { };
    "Mod+Alt+Tab".action.move-workspace-to-monitor-next = { };

    "Mod+Ctrl+Q".action.spawn = ctl.lock;
    "Mod+Shift+Q".action.power-off-monitors = { };
    "Mod+Alt+Q".action.spawn = ctl.sleep;

    # TODO markup screenshots
    "Mod+P".action.screenshot = { };
    "Mod+Ctrl+P".action.screenshot-window = { };
    "Mod+Shift+P".action.screenshot-screen = { };
    "Mod+Alt+P".action.spawn = [ (toString record) ];

    "Mod+N".action.spawn = noctaliaMsg [ "notification-invoke-latest" ];
    "Mod+Shift+N".action.spawn = noctaliaMsg [ "notification-clear-active" ];
    "Mod+Alt+N".action.spawn = noctaliaMsg [ "notification-dnd-toggle" ];

    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+Ctrl+Minus".action.set-window-height = "-10%";
    "Mod+Ctrl+Equal".action.set-window-height = "+10%";

    "Mod+Comma".action."focus-column-first" = { };
    "Mod+Period".action."focus-column-last" = { };
    "Mod+Ctrl+Comma".action."move-column-to-first" = { };
    "Mod+Ctrl+Period".action."move-column-to-last" = { };

    "Mod+H".action."focus-column-left" = { };
    "Mod+Ctrl+H".action."consume-or-expel-window-left" = { };
    "Mod+Shift+H".action."move-column-left" = { };

    "Mod+L".action."focus-column-right" = { };
    "Mod+Ctrl+L".action."consume-or-expel-window-right" = { };
    "Mod+Shift+L".action."move-column-right" = { };

    "Mod+J".action."focus-window-or-workspace-down" = { };
    "Mod+Ctrl+J".action."move-window-down-or-to-workspace-down" = { };
    "Mod+Shift+J".action."move-column-to-workspace-down" = { };
    "Mod+Alt+J".action."move-workspace-down" = { };

    "Mod+K".action."focus-window-or-workspace-up" = { };
    "Mod+Ctrl+K".action."move-window-up-or-to-workspace-up" = { };
    "Mod+Shift+K".action."move-column-to-workspace-up" = { };
    "Mod+Alt+K".action."move-workspace-up" = { };

    "Mod+M".action."switch-focus-between-floating-and-tiling" = { };
    "Mod+Ctrl+M".action."toggle-window-floating" = { };

    "Mod+T".action."toggle-column-tabbed-display" = { };

    "Mod+Escape".action."toggle-keyboard-shortcuts-inhibit" = { };

    "Mod+I".action."consume-window-into-column" = { };
    "Mod+O".action."expel-window-from-column" = { };

    "Mod+R".action."switch-preset-column-width" = { };
    "Mod+Ctrl+R".action."switch-preset-window-height" = { };
    "Mod+Shift+R".action."reset-window-height" = { };

    "Mod+F".action."maximize-column" = { };
    "Mod+Ctrl+F".action."fullscreen-window" = { };

    "Mod+C".action."center-column" = { };
    "Mod+Ctrl+C".action."center-visible-columns" = { };

    XF86MonBrightnessDown = mkGlobal ctl.brightness.down;
    XF86MonBrightnessUp = mkGlobal ctl.brightness.up;
    XF86AudioMicMute = mkGlobal ctl.sound.muteMic;
    XF86AudioMute = mkGlobal ctl.sound.mute;
    XF86AudioLowerVolume = mkGlobal ctl.sound.down;
    XF86AudioRaiseVolume = mkGlobal ctl.sound.up;
    XF86AudioPrev = mkGlobal ctl.playback.prev;
    XF86AudioNext = mkGlobal ctl.playback.next;
    XF86AudioStop = mkGlobal ctl.playback.stop;
    XF86AudioPlay = mkGlobal ctl.playback.playPause;
    XF86Wlan = mkGlobal ctl.wlan;
    XF86Bluetooth = mkGlobal ctl.bluetooth;
  }
  // lib.mergeAttrsList (
    map (
      i:
      let
        n = toString i;
      in
      {
        "Mod+${n}".action.focus-workspace = i;
        "Mod+Ctrl+${n}".action.move-window-to-workspace = i;
        "Mod+Shift+${n}".action.move-column-to-workspace = i;
      }
    ) (lib.range 1 9)
  );
}
