{ config, pkgs, ... }:
let
  # Terminal commands
  term = o: "${o.exec} foot";
  term_float = o: "${o.exec} foot -a foot-float -W 88x28";

  # Menu and applications
  # TODO move package references here, remove from sys pkgs
  bookdir = "~/books";
  bemenu = "bemenu";
  zathura = "zathura";
  j4 = "j4-dmenu-desktop";
  todo = "todo";
  fd = "fd";
  killall = "killall";
  makoctl = "makoctl";
  grim = "grim";
  swappy = "swappy";
  wf-recorder = "wf-recorder";
  slurp = "slurp";
  jq = "jq";

  # swaymsg exec
  # hyprctl dispatch exec
  books =
    o:
    ''${o.exec} ${killall} ${bemenu} || ${o.execCmd} "echo \"$(cd ${bookdir} && ${fd} -t f | ${bemenu} -p read -l 20)\" | xargs -rI{} ${zathura} '${bookdir}/{}'"'';
  drun =
    o:
    ''${o.exec} ${killall} ${bemenu} || ${o.execCmd} "$(${j4} -d '${bemenu} -p drun' -t ${term o} -x --no-generic)"'';
  todo_add =
    o:
    ''${o.exec} ${killall} ${bemenu} || ${o.execCmd} "$(echo ''' | ${bemenu} -p ${todo} -l 0 | xargs -I{} ${todo} add \"{}\")"'';
  todo_done =
    o:
    ''${o.exec} ${killall} ${bemenu} || ${o.execCmd} "$(${todo} ls | tac | ${bemenu} -p done | sed 's/^\s*//' | cut -d ' ' -f 1 | xargs ${todo} rm)"'';
  lock = o: "${o.exec} loginctl lock-session";

  # Notifications
  invoke_notification = o: "${o.exec} ${makoctl} invoke";
  dismiss_notification = o: "${o.exec} ${makoctl} dismiss";
  dismiss_all_notifications = o: "${o.exec} ${makoctl} dismiss --all";

  # Screenshots
  screenshot_mouse = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${grim} -g \"{}\" - | ${swappy} -f -";
  screenshot_focused_window = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.focused) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | xargs -I {} ${grim} -g \"{}\" - | ${swappy} -f -";
  screenshot_all_outputs = "exec ${grim} - | ${swappy} -f -";
  screenshot_focused_output = "exec ${grim} -o $(swaymsg -t get_outputs | ${jq} -r '.[] | select(.focused) | .name') - | ${swappy} -f -";

  # Screencasting
  screencast_mouse = "exec killall --signal SIGINT || swaymsg -t get_tree | ${jq} -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${wf-recorder} -g \"{}\" -f \"~/vid/screen/$(date +%Y-%m-%d_%H-%M-%S).mp4\"";

  # Special keys - brightness
  brightnessFunc =
    o:
    let
      l = v: "${o.exec} ${pkgs.avizo}/bin/lightctl ${v}";
    in
    {
      up = l "up";
      down = l "down";
    };

  # Special keys - sound
  soundFunc =
    o:
    let
      l = v: "${o.exec} ${pkgs.avizo}/bin/volumectl ${v}";
    in
    {
      up = l "-u up";
      down = l "-u down";
      mute = l "toggle-mute";
      muteMic = l "-m toggle-mute";
    };

  # Special keys - audio control
  audioFunc =
    o:
    let
      l = v: "${o.exec} ${pkgs.playerctl}/bin/playerctl -p spotify ${v}";
    in
    {
      prev = l "previous";
      next = l "next";
      playPause = l "play-pause";
      stop = l "stop";
    };

  # Special keys - toggles
  wlan = o: "${o.exec} ${pkgs.tlp}/bin/wifi toggle";
  bluetooth = o: "${o.exec} ${pkgs.tlp}/bin/bluetooth toggle";

  inherit (config.wayland.windowManager.sway.config)
    down
    up
    left
    right
    modifier
    ;

  sleep = o: "${o.exec} systemctl suspend";

  mod2 = "ctrl";
  mod3 = "shift";
  mod4 = "alt";

  floatNotes =
    o: "${term_float o} --working-directory=\"$HOME/notes\" -e bash $EDITOR ~/notes/scratchpad.md";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings =
      let
        modifier = "SUPER";
        mod2 = "CTRL";
        mod3 = "shift";
        o = {
          exec = "exec,";
          execCmd = "hyprctl dispatch exec";
        };
      in
      {
        windowrule = [
          "float,title:^(foot-float)$"
          "suppressevent maximize, class:.*"
        ];
        bind = [
          "${modifier}, semicolon, ${term o}"
          "${modifier} ${mod2}, semicolon, ${term_float o}"
          "${modifier}, apostrophe, ${floatNotes o}"
          "${modifier}, q, killactive"
          "${modifier} ${mod2}, q, ${lock o}"
          "${modifier} ${mod3}, q, ${sleep o}"
          "${modifier}, space, ${drun o}"
          "${modifier}, r, ${books o}"
          "${modifier}, t, ${todo_add o}"
          "${modifier} ${mod2}, t, ${todo_done o}"
          "${modifier} ${mod2}, m, togglefloating"

          "${modifier}, P, pseudo,"
          "${modifier}, J, togglesplit,"

          "${modifier}, h, movefocus, l"
          "${modifier}, l, movefocus, r"
          "${modifier}, k, movefocus, u"
          "${modifier}, j, movefocus, d"

          "${modifier}, 1, workspace, 1"
          "${modifier}, 2, workspace, 2"
          "${modifier}, 3, workspace, 3"
          "${modifier}, 4, workspace, 4"
          "${modifier}, 5, workspace, 5"
          "${modifier}, 6, workspace, 6"
          "${modifier}, 7, workspace, 7"
          "${modifier}, 8, workspace, 8"
          "${modifier}, 9, workspace, 9"
          "${modifier}, 0, workspace, 10"

          "${modifier} SHIFT, 1, movetoworkspace, 1"
          "${modifier} SHIFT, 2, movetoworkspace, 2"
          "${modifier} SHIFT, 3, movetoworkspace, 3"
          "${modifier} SHIFT, 4, movetoworkspace, 4"
          "${modifier} SHIFT, 5, movetoworkspace, 5"
          "${modifier} SHIFT, 6, movetoworkspace, 6"
          "${modifier} SHIFT, 7, movetoworkspace, 7"
          "${modifier} SHIFT, 8, movetoworkspace, 8"
          "${modifier} SHIFT, 9, movetoworkspace, 9"
          "${modifier} SHIFT, 0, movetoworkspace, 10"

          # # Example special workspace (scratchpad)
          # bind = $mainMod, S, togglespecialworkspace, magic
          # bind = $mainMod SHIFT, S, movetoworkspace, special:magic

          # # Requires playerctl
        ];
        bindl =
          let
            audio = audioFunc o;
          in
          [
            ", XF86AudioNext, ${audio.next}"
            ", XF86AudioPause, ${audio.stop}"
            ", XF86AudioPlay, ${audio.playPause}"
            ", XF86AudioPrev, ${audio.prev}"
          ];
        bindel =
          let
            sound = soundFunc o;
            brightness = brightnessFunc o;
          in
          [
            ",XF86AudioRaiseVolume, ${sound.up}"
            ",XF86AudioLowerVolume, ${sound.down}"
            ",XF86AudioMute, ${sound.mute}"
            ",XF86AudioMicMute, ${sound.muteMic}"
            ",XF86MonBrightnessUp, ${brightness.up}"
            ",XF86MonBrightnessDown, ${brightness.down}"
          ];
        bindm = [
          "${modifier}, mouse:272, movewindow"
          "${modifier}, mouse:273, resizewindow"
        ];
      };
  };

  wayland.windowManager.sway.config = {

    # Keybindings
    keybindings =
      let
        o = {
          exec = "exec";
          execCmd = "swaymsg exec";
        };
        sound = soundFunc o;
        brightness = brightnessFunc o;
        audio = audioFunc o;
      in
      {
        # Terminal and basic commands
        "${modifier}+semicolon" = term o;
        "${modifier}+${mod2}+semicolon" = term_float o;
        "${modifier}+apostrophe" = floatNotes o;
        "${modifier}+slash" = "reload";
        "${modifier}+q" = "kill";
        "${modifier}+${mod2}+q" = lock o;
        "${modifier}+${mod3}+q" = sleep o;
        "${modifier}+space" = drun o;
        "${modifier}+r" = books o;
        "${modifier}+t" = todo_add o;
        "${modifier}+${mod2}+t" = todo_done o;
        "${modifier}+y" = "sticky toggle";

        # Layout
        "${modifier}+o" = "focus parent";
        "${modifier}+i" = "focus child";
        "${modifier}+a" = "layout tabbed";
        "${modifier}+s" = "layout stacking";
        "${modifier}+d" = "layout toggle split";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+${mod2}+f" = "fullscreen toggle global";
        "${modifier}+z" = "split none";
        "${modifier}+v" = "split horizontal";
        "${modifier}+c" = "split vertical";

        # Floats
        "${modifier}+m" = "focus mode_toggle";
        "${modifier}+${mod2}+m" = "floating toggle";
        "${modifier}+u" = "scratchpad show";
        "${modifier}+${mod2}+u" = "move scratchpad";

        # Notifications
        "${modifier}+n" = invoke_notification o;
        "${modifier}+${mod2}+n" = dismiss_notification o;
        "${modifier}+Shift+n" = dismiss_all_notifications o;

        # Screenshots
        "${modifier}+p" = screenshot_mouse;
        "${modifier}+${mod2}+p" = screenshot_focused_output;
        "${modifier}+${mod4}+p" = screencast_mouse;

        # Moving focus
        "${modifier}+${left}" = "focus left";
        "${modifier}+${down}" = "focus down";
        "${modifier}+${up}" = "focus up";
        "${modifier}+${right}" = "focus right";

        # Moving windows
        "${modifier}+${mod2}+${left}" = "move left 200 ppt";
        "${modifier}+${mod2}+${down}" = "move down 200 ppt";
        "${modifier}+${mod2}+${up}" = "move up 200 ppt";
        "${modifier}+${mod2}+${right}" = "move right 200 ppt";
        "${modifier}+${mod2}+tab" = "move workspace back_and_forth";
        "${modifier}+${mod2}+c" = "move position cursor";

        # Moving workspaces
        "${modifier}+${mod3}+${left}" = "move workspace to output left";
        "${modifier}+${mod3}+${down}" = "move workspace to output down";
        "${modifier}+${mod3}+${up}" = "move workspace to output up";
        "${modifier}+${mod3}+${right}" = "move workspace to output right";

        # Resizing
        "${modifier}+${mod4}+${left}" = "resize shrink width 50 px";
        "${modifier}+${mod4}+${down}" = "resize shrink height 50 px";
        "${modifier}+${mod4}+${up}" = "resize grow height 50 px";
        "${modifier}+${mod4}+${right}" = "resize grow width 50 px";

        # Switching between workspaces
        "${modifier}+tab" = "workspace back_and_forth";
        "${modifier}+1" = "workspace 1:1";
        "${modifier}+2" = "workspace 2:2";
        "${modifier}+3" = "workspace 3:3";
        "${modifier}+4" = "workspace 4:4";
        "${modifier}+5" = "workspace 5:5";
        "${modifier}+6" = "workspace 6:6";
        "${modifier}+7" = "workspace 7:7";
        "${modifier}+8" = "workspace 8:8";
        "${modifier}+9" = "workspace 9:9";
        "${modifier}+0" = "workspace 10:0";

        # Moving windows between workspaces
        "${modifier}+${mod2}+1" = "move container to workspace 1:1";
        "${modifier}+${mod2}+2" = "move container to workspace 2:2";
        "${modifier}+${mod2}+3" = "move container to workspace 3:3";
        "${modifier}+${mod2}+4" = "move container to workspace 4:4";
        "${modifier}+${mod2}+5" = "move container to workspace 5:5";
        "${modifier}+${mod2}+6" = "move container to workspace 6:6";
        "${modifier}+${mod2}+7" = "move container to workspace 7:7";
        "${modifier}+${mod2}+8" = "move container to workspace 8:8";
        "${modifier}+${mod2}+9" = "move container to workspace 9:9";
        "${modifier}+${mod2}+0" = "move container to workspace 10:0";

        # Special keys (media and hardware controls)
        "XF86MonBrightnessDown" = brightness.down;
        "XF86MonBrightnessUp" = brightness.up;
        "XF86AudioMicMute" = sound.muteMic;
        "XF86AudioMute" = sound.mute;
        "XF86AudioLowerVolume" = sound.down;
        "XF86AudioRaiseVolume" = sound.up;
        "XF86AudioPrev" = audio.prev;
        "XF86AudioNext" = audio.next;
        "XF86AudioStop" = audio.stop;
        "XF86AudioPlay" = audio.playPause;
        "XF86Wlan" = wlan o;
        "XF86Bluetooth" = bluetooth o;
      };
  };
}
