{
  config,
  pkgs,
  lib,
  ...
}@args:
let

  left = "h";
  down = "j";
  up = "k";
  right = "l";

  mod1 = "Mod4";
  mod2 = "ctrl";
  mod3 = "shift";
  mod4 = "alt";

  inherit (import ./rhs.nix args)
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
    inherit mod1;

    floating = { inherit mod1; };

    # Keybindings
    keybindings = {
      # Terminal and basic commands
      "${mod1}+semicolon" = term.default;
      "${mod1}+${mod2}+semicolon" = term.float;
      "${mod1}+apostrophe" = float_notes;
      "${mod1}+slash" = "reload";
      "${mod1}+q" = "kill";
      "${mod1}+${mod2}+q" = ctl.lock;
      "${mod1}+${mod3}+q" = ctl.sleep;
      "${mod1}+space" = pickers.drun;
      "${mod1}+r" = pickers.books;
      "${mod1}+t" = pickers.todo_add;
      "${mod1}+${mod2}+t" = pickers.todo_done;
      "${mod1}+y" = "sticky toggle";

      # Layout
      "${mod1}+o" = "focus parent";
      "${mod1}+i" = "focus child";
      "${mod1}+a" = "layout tabbed";
      "${mod1}+s" = "layout stacking";
      "${mod1}+d" = "layout toggle split";
      "${mod1}+f" = "fullscreen toggle";
      "${mod1}+${mod2}+f" = "fullscreen toggle global";
      "${mod1}+z" = "split none";
      "${mod1}+v" = "split horizontal";
      "${mod1}+c" = "split vertical";

      # Floats
      "${mod1}+m" = "focus mode_toggle";
      "${mod1}+${mod2}+m" = "floating toggle";
      "${mod1}+u" = "scratchpad show";
      "${mod1}+${mod2}+u" = "move scratchpad";

      # Notifications
      "${mod1}+n" = notifications.invoke;
      "${mod1}+${mod2}+n" = notifications.dismiss;
      "${mod1}+Shift+n" = notifications.dismiss_all;

      # Screenshots
      "${mod1}+p" = screen.shot.mouse;
      "${mod1}+${mod2}+p" = screen.shot.output;
      "${mod1}+${mod4}+p" = screen.cast.selection;

      # Moving focus
      "${mod1}+${left}" = "focus left";
      "${mod1}+${down}" = "focus down";
      "${mod1}+${up}" = "focus up";
      "${mod1}+${right}" = "focus right";

      # Moving windows
      "${mod1}+${mod2}+${left}" = "move left 200 ppt";
      "${mod1}+${mod2}+${down}" = "move down 200 ppt";
      "${mod1}+${mod2}+${up}" = "move up 200 ppt";
      "${mod1}+${mod2}+${right}" = "move right 200 ppt";
      "${mod1}+${mod2}+tab" = "move workspace back_and_forth";
      "${mod1}+${mod2}+c" = "move position cursor";

      # Moving workspaces
      "${mod1}+${mod3}+${left}" = "move workspace to output left";
      "${mod1}+${mod3}+${down}" = "move workspace to output down";
      "${mod1}+${mod3}+${up}" = "move workspace to output up";
      "${mod1}+${mod3}+${right}" = "move workspace to output right";

      # Resizing
      "${mod1}+${mod4}+${left}" = "resize shrink width 50 px";
      "${mod1}+${mod4}+${down}" = "resize shrink height 50 px";
      "${mod1}+${mod4}+${up}" = "resize grow height 50 px";
      "${mod1}+${mod4}+${right}" = "resize grow width 50 px";

      # Switching between workspaces
      "${mod1}+tab" = "workspace back_and_forth";
      "${mod1}+1" = "workspace 1:1";
      "${mod1}+2" = "workspace 2:2";
      "${mod1}+3" = "workspace 3:3";
      "${mod1}+4" = "workspace 4:4";
      "${mod1}+5" = "workspace 5:5";
      "${mod1}+6" = "workspace 6:6";
      "${mod1}+7" = "workspace 7:7";
      "${mod1}+8" = "workspace 8:8";
      "${mod1}+9" = "workspace 9:9";
      "${mod1}+0" = "workspace 10:0";

      # Moving windows between workspaces
      "${mod1}+${mod2}+1" = "move container to workspace 1:1";
      "${mod1}+${mod2}+2" = "move container to workspace 2:2";
      "${mod1}+${mod2}+3" = "move container to workspace 3:3";
      "${mod1}+${mod2}+4" = "move container to workspace 4:4";
      "${mod1}+${mod2}+5" = "move container to workspace 5:5";
      "${mod1}+${mod2}+6" = "move container to workspace 6:6";
      "${mod1}+${mod2}+7" = "move container to workspace 7:7";
      "${mod1}+${mod2}+8" = "move container to workspace 8:8";
      "${mod1}+${mod2}+9" = "move container to workspace 9:9";
      "${mod1}+${mod2}+0" = "move container to workspace 10:0";

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
