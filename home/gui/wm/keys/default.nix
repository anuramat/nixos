{
  pkgs,
  lib,
  ...
}@args:
let
  modifier = "Mod4";

  left = "h";
  down = "j";
  up = "k";
  right = "l";

  mod2 = "ctrl";
  mod3 = "shift";
  mod4 = "alt";

  inherit (import ./rhs.nix args)
    cycle_outputs
    float_notes
    term
    screen
    pickers
    notifications
    ctl
    ;
in
{
  wayland.windowManager.sway.config = {
    bindkeysToCode = true;
    inherit modifier;

    floating = { inherit modifier; };

    # Keybindings
    keybindings = {
      # Terminal and basic commands
      "${modifier}+semicolon" = term.default;
      "${modifier}+${mod2}+semicolon" = term.float;
      "${modifier}+apostrophe" = float_notes;
      "${modifier}+slash" = "reload";
      "${modifier}+q" = "kill";
      "${modifier}+${mod2}+q" = ctl.lock;
      "${modifier}+${mod3}+q" = ctl.sleep;
      "${modifier}+space" = pickers.drun;
      "${modifier}+r" = pickers.books;
      "${modifier}+t" = pickers.todo_add;
      "${modifier}+${mod2}+t" = pickers.todo_done;
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
      "${modifier}+n" = notifications.invoke;
      "${modifier}+${mod2}+n" = notifications.dismiss;
      "${modifier}+Shift+n" = notifications.dismiss_all;

      # Screenshots
      "${modifier}+p" = screen.shot.selection;
      "${modifier}+${mod2}+p" = screen.shot.focused.output;
      "${modifier}+${mod4}+p" = screen.cast.selection;

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
      "${modifier}+${mod2}+tab" = cycle_outputs;
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
      "XF86MonBrightnessDown" = ctl.brightness.down;
      "XF86MonBrightnessUp" = ctl.brightness.up;
      "XF86AudioMicMute" = ctl.sound.muteMic;
      "XF86AudioMute" = ctl.sound.mute;
      "XF86AudioLowerVolume" = ctl.sound.down;
      "XF86AudioRaiseVolume" = ctl.sound.up;
      "XF86AudioPrev" = ctl.playback.prev;
      "XF86AudioNext" = ctl.playback.next;
      "XF86AudioStop" = ctl.playback.stop;
      "XF86AudioPlay" = ctl.playback.playPause;
      "XF86Wlan" = ctl.wlan;
      "XF86Bluetooth" = ctl.bluetooth;
    };
  };
}
