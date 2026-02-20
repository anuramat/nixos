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
        l = v: [
          "${pkgs.avizo}/bin/lightctl"
          v
        ];
      in
      {
        up = l "up";
        down = l "down";
      };
    sound =
      let
        l = v: [
          "${pkgs.avizo}/bin/volumectl"
          v
        ];
      in
      {
        up = l "-u up";
        down = l "-u down";
        mute = l "toggle-mute";
        muteMic = l "-m toggle-mute";
      };
    playback =
      let
        # `-p spotify` for specific player
        l = v: [
          "${pkgs.playerctl}/bin/playerctl"
          v
        ];
      in
      {
        prev = l "previous";
        next = l "next";
        playPause = l "play-pause";
        stop = l "stop";
      };
    bluetooth = [
      "${pkgs.tlp}/bin/bluetooth"
      "toggle"
    ];
    lock = [
      "loginctl"
      "lock-session"
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
        pkgs.writeShellScript "mkmenu" ''
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
            "$(${j4} -d '${bemenu} -p drun' -t '${term}' -x --no-generic)"
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

  # TODO markup screenshots

  mkCtl = x: {
    allow-when-locked = true;
    action.spawn = x;
  };

in

{
  programs.niri.settings.binds = {

    "Mod+Q" = {
      action."close-window" = { };
      repeat = false;
    };
    "Mod+semicolon".action.spawn = "foot";
    "Mod+Shift+Slash".action.show-hotkey-overlay = { };
    "Mod+Space".action.spawn = pickers.drun;
    "Mod+Ctrl+Q".action.spawn = [
      "loginctl"
      "lock-session"
    ];
    "Mod+P".action.screenshot = { };
    "Mod+Ctrl+P".action.screenshot-window = { };
    "Mod+Shift+P".action.screenshot-screen = { };
    "Alt+Space".action.switch-layout = { };

    "Mod+Minus".action."set-column-width" = "-10%";
    "Mod+Equal".action."set-column-width" = "+10%";
    "Mod+Shift+Minus".action."set-window-height" = "-10%";
    "Mod+Shift+Equal".action."set-window-height" = "+10%";
    "Mod+V".action."toggle-window-floating" = { };
    "Mod+Shift+V".action."switch-focus-between-floating-and-tiling" = { };
    "Mod+W".action."toggle-column-tabbed-display" = { };

    "Mod+H".action."focus-column-left" = { };
    "Mod+L".action."focus-column-right" = { };
    "Mod+J".action."focus-window-down" = { };
    "Mod+K".action."focus-window-up" = { };

    "Mod+Ctrl+H".action."move-column-left" = { };
    "Mod+Ctrl+L".action."move-column-right" = { };
    "Mod+Ctrl+J".action."move-window-down" = { };
    "Mod+Ctrl+K".action."move-window-up" = { };

    "Mod+Shift+H".action."focus-monitor-left" = { };
    "Mod+Shift+L".action."focus-monitor-right" = { };
    "Mod+Shift+J".action."focus-monitor-down" = { };
    "Mod+Shift+K".action."focus-monitor-up" = { };

    # NOTE
    # Keep in mind that niri is a dynamic workspace system, so these commands
    # are kind of "best effort". Trying to refer to a workspace index bigger
    # than the current workspace count will instead refer to the bottommost
    # (empty) workspace.
    #
    # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on will
    # all refer to the 3rd workspace.

    "Mod+1".action."focus-workspace" = 1;
    "Mod+2".action."focus-workspace" = 2;
    "Mod+3".action."focus-workspace" = 3;
    "Mod+4".action."focus-workspace" = 4;
    "Mod+5".action."focus-workspace" = 5;
    "Mod+6".action."focus-workspace" = 6;
    "Mod+7".action."focus-workspace" = 7;
    "Mod+8".action."focus-workspace" = 8;
    "Mod+9".action."focus-workspace" = 9;

    "Mod+Ctrl+1".action."move-column-to-workspace" = 1;
    "Mod+Ctrl+2".action."move-column-to-workspace" = 2;
    "Mod+Ctrl+3".action."move-column-to-workspace" = 3;
    "Mod+Ctrl+4".action."move-column-to-workspace" = 4;
    "Mod+Ctrl+5".action."move-column-to-workspace" = 5;
    "Mod+Ctrl+6".action."move-column-to-workspace" = 6;
    "Mod+Ctrl+7".action."move-column-to-workspace" = 7;
    "Mod+Ctrl+8".action."move-column-to-workspace" = 8;
    "Mod+Ctrl+9".action."move-column-to-workspace" = 9;

    "Mod+Tab".action."focus-workspace-previous" = { };
    "Mod+BracketLeft".action."consume-or-expel-window-left" = { };
    "Mod+BracketRight".action."consume-or-expel-window-right" = { };

    "XF86MonBrightnessDown" = mkCtl ctl.brightness.down;
    "XF86MonBrightnessUp" = mkCtl ctl.brightness.up;
    "XF86AudioMicMute" = mkCtl ctl.sound.muteMic;
    "XF86AudioMute" = mkCtl ctl.sound.mute;
    "XF86AudioLowerVolume" = mkCtl ctl.sound.down;
    "XF86AudioRaiseVolume" = mkCtl ctl.sound.up;
    "XF86AudioPrev" = mkCtl ctl.playback.prev;
    "XF86AudioNext" = mkCtl ctl.playback.next;
    "XF86AudioStop" = mkCtl ctl.playback.stop;
    "XF86AudioPlay" = mkCtl ctl.playback.playPause;
    "XF86Wlan" = mkCtl ctl.wlan;
    "XF86Bluetooth" = mkCtl ctl.bluetooth;
  };
}
