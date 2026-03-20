{
  lib,
  config,
  pkgs,
  ...
}:
let
  # TODO parameterize or smth
  bookdir = "${config.home.homeDirectory}/books";

  inherit (lib) getExe;

  ctl = {
    brightness =
      let
        bin = "${pkgs.avizo}/bin/lightctl";
      in
      {
        up = [
          bin
          "up"
        ];
        down = [
          bin
          "down"
        ];
      };
    sound =
      let
        bin = "${pkgs.avizo}/bin/volumectl";
      in
      {
        up = [
          bin
          "-u"
          "up"
        ];
        down = [
          bin
          "-u"
          "down"
        ];
        mute = [
          bin
          "toggle-mute"
        ];
        muteMic = [
          bin
          "-m"
          "toggle-mute"
        ];
      };
    playback =
      let
        # `-p spotify` for specific player
        bin = "${pkgs.playerctl}/bin/playerctl";
      in
      {
        prev = [
          bin
          "previous"
        ];
        next = [
          bin
          "next"
        ];
        playPause = [
          bin
          "play-pause"
        ];
        stop = [
          bin
          "stop"
        ];
      };
    bluetooth = [
      "${pkgs.tlp}/bin/bluetooth"
      "toggle"
    ];
    lock = [
      (getExe pkgs.swaylock-plugin)
      "-f"
    ];
    sleep = [
      "systemctl"
      "suspend"
    ];
    wlan = [
      "${pkgs.tlp}/bin/wifi"
      "toggle"
    ];
  };

  term = "${config.home.sessionVariables.TERMCMD}";

  pickers =
    let
      j4 = getExe pkgs.j4-dmenu-desktop;
      pkill = "${pkgs.procps}/bin/pkill";
      todo = getExe pkgs.todo;
      fd = getExe pkgs.fd;
      zathura = getExe pkgs.zathura;
      bemenu = getExe pkgs.bemenu;

      mkMenu =
        name: command:
        pkgs.writeShellScript name ''
          if ${pkill} -x bemenu; then
            exit 0
          fi
          ${command}
        ''
        |> toString;
      commands = {
        books =
          # bash
          ''
            cd ${bookdir}
            book=$(${fd} . "${bookdir}" -at f | ${bemenu} -p read -l 20) || exit
            ${zathura} $book
          '';
        drun =
          # bash
          ''
            selected="$(${j4} -d '${bemenu} -p drun' -t '${term}' --no-exec --no-generic)"
            bash -lc "exec $selected"
          '';
        todo_add =
          # bash
          ''
            task=$(echo "" | ${bemenu} -p todo -l 0) || exit
            ${todo} add "$task"
          '';
        todo_done =
          # bash
          ''
            task=$(${todo} ls | tac | ${bemenu} -p done) || exit
            task_id=$(echo "$task" | sed 's/^\s*//' | cut -d ' ' -f 1)
            ${todo} rm "$task_id"
          '';
      };
    in
    lib.mapAttrs (name: cmd: mkMenu "${name}-dmenu" cmd) commands;

  notifications =
    let
      makoctl = "${pkgs.mako}/bin/makoctl";
    in
    {
      invoke = [
        makoctl
        "invoke"
      ];
      dismiss = [
        makoctl
        "dismiss"
      ];
      dismiss_all = [
        makoctl
        "dismiss"
        "--all"
      ];
    };

  mkCtl = x: {
    allow-when-locked = true;
    action.spawn = x;
  };

  record =
    let
      dir = "${config.home.sessionVariables.XDG_VIDEOS_DIR}/screen";
      bin = getExe pkgs.gpu-screen-recorder;
      pkill = "${pkgs.procps}/bin/pkill";
    in
    pkgs.writeShellScript "record" ''
      if ! ${pkill} -INT -x gpu-screen-reco; then
        mkdir -p ${dir}
        ${bin} -w screen -o "${dir}/$(date +%Y-%m-%d_%H-%M-%S).mp4"
      fi
    '';

in

{
  programs.niri.settings.binds = {

    "Mod+Slash".action.show-hotkey-overlay = { };

    "Alt+Space".action.switch-layout = "next";
    "Mod+Q" = {
      action."close-window" = { };
      repeat = false;
    };
    "Mod+semicolon".action.spawn = getExe pkgs.foot;
    "Mod+Space".action.spawn = pickers.drun;
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

    "Mod+N".action.spawn = notifications.invoke;
    "Mod+Ctrl+N".action.spawn = notifications.dismiss;
    "Mod+Shift+N".action.spawn = notifications.dismiss_all;

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

    # TODO Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    "Mod+I".action."consume-window-into-column" = { };
    "Mod+O".action."expel-window-from-column" = { };

    "Mod+R".action."switch-preset-column-width" = { };
    "Mod+Ctrl+R".action."switch-preset-window-height" = { };
    "Mod+Shift+R".action."reset-window-height" = { };

    "Mod+F".action."maximize-column" = { };
    "Mod+Ctrl+F".action."fullscreen-window" = { };

    "Mod+C".action."center-column" = { };
    "Mod+Ctrl+C".action."center-visible-columns" = { };

    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    "Mod+Ctrl+1".action.move-window-to-workspace = 1;
    "Mod+Ctrl+2".action.move-window-to-workspace = 2;
    "Mod+Ctrl+3".action.move-window-to-workspace = 3;
    "Mod+Ctrl+4".action.move-window-to-workspace = 4;
    "Mod+Ctrl+5".action.move-window-to-workspace = 5;
    "Mod+Ctrl+6".action.move-window-to-workspace = 6;
    "Mod+Ctrl+7".action.move-window-to-workspace = 7;
    "Mod+Ctrl+8".action.move-window-to-workspace = 8;
    "Mod+Ctrl+9".action.move-window-to-workspace = 9;

    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    XF86MonBrightnessDown = mkCtl ctl.brightness.down;
    XF86MonBrightnessUp = mkCtl ctl.brightness.up;
    XF86AudioMicMute = mkCtl ctl.sound.muteMic;
    XF86AudioMute = mkCtl ctl.sound.mute;
    XF86AudioLowerVolume = mkCtl ctl.sound.down;
    XF86AudioRaiseVolume = mkCtl ctl.sound.up;
    XF86AudioPrev = mkCtl ctl.playback.prev;
    XF86AudioNext = mkCtl ctl.playback.next;
    XF86AudioStop = mkCtl ctl.playback.stop;
    XF86AudioPlay = mkCtl ctl.playback.playPause;
    XF86Wlan = mkCtl ctl.wlan;
    XF86Bluetooth = mkCtl ctl.bluetooth;
  };
}
