{ config, ... }:
let
  # Terminal commands
  term = "exec foot";
  term_float = "exec foot -a foot-float -W 88x28";

  # Menu and applications
  bookdir = "~/books";
  bemenu = "bemenu";
  zathura = "zathura";
  j4 = "j4-dmenu-desktop";

  books = "exec killall ${bemenu} || swaymsg exec \"echo \\\"$(cd $bookdir && fd -t f | ${bemenu} -p read -l 20)\\\" | xargs -rI{} ${zathura} '$bookdir/{}'\"";
  drun = "exec killall ${bemenu} || swaymsg exec \"$(${j4} -d '${bemenu} -p drun' -t $term -x --no-generic)\"";
  todo_add = "exec killall ${bemenu} || swaymsg exec \"$(echo '' | ${bemenu} -p task -l 0 | xargs -I{} todo add \\\"{}\\\")\"";
  todo_done = "exec killall ${bemenu} || swaymsg exec \"$(todo ls | tac | ${bemenu} -p done | sed 's/^\\s*//' | cut -d ' ' -f 1 | xargs todo rm)\"";
  lock = "exec loginctl lock-session";

  # Notifications
  invoke_notification = "exec makoctl invoke";
  dismiss_notification = "exec makoctl dismiss";
  dismiss_all_notifications = "exec makoctl dismiss --all";

  # Screenshots
  screenshot_mouse = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | slurp | xargs -I {} grim -g \"{}\" - | swappy -f -";
  screenshot_focused_window = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.focused) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | xargs -I {} grim -g \"{}\" - | swappy -f -";
  screenshot_all_outputs = "exec grim - | swappy -f -";
  screenshot_focused_output = "exec grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') - | swappy -f -";

  # Screencasting
  screencast_mouse = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | slurp | xargs -I {} wf-recorder -g \"{}\" -f \"~/vid/screen/$(date +%Y-%m-%d_%H-%M-%S).mp4\"";
  screencast_stop = "exec killall wf-recorder";

  # Special keys - brightness
  brightness =
    let
      l = v: "exec lightctl ${v}";
    in
    {
      up = l "up";
      down = l "down";
    };

  # Special keys - sound
  sound =
    let
      l = v: "exec volumectl ${v}";
    in
    {
      up = l "-u up";
      down = l "-u down";
      mute = l "toggle-mute";
      muteMic = l "-m toggle-mute";
    };

  # Special keys - audio control
  audio =
    let
      l = v: "exec playerctl -p spotify ${v}";
    in
    {
      prev = l "previous";
      next = l "next";
      playPause = l "play-pause";
      stop = l "stop";
    };

  # Special keys - toggles
  wlan = "exec wifi toggle";
  bluetooth = "exec bluetooth toggle";

  config = config.wayland.windowManager.sway.config;
  inherit (config)
    down
    up
    left
    right
    ;

  sleep = "exec systemctl suspend";

  mod = config.modifier;
  mod2 = "ctrl";
  mod3 = "shift";
  mod4 = "alt";
in
{
  wayland.windowManager.sway.config = {

    # Keybindings
    keybindings = {
      # Terminal and basic commands
      "${mod}+semicolon" = term;
      "${mod}+${mod2}+semicolon" = term_float;
      "${mod}+apostrophe" =
        "${term_float} --working-directory=\"$HOME/notes\" -e bash $EDITOR ~/notes/scratchpad.md";
      "${mod}+slash" = "reload";
      "${mod}+q" = "kill";
      "${mod}+${mod2}+q" = lock;
      "${mod}+${mod3}+q" = sleep;
      "${mod}+space" = drun;
      "${mod}+r" = books;
      "${mod}+t" = todo_add;
      "${mod}+${mod2}+t" = todo_done;
      "${mod}+y" = "sticky toggle";

      # Layout
      "${mod}+o" = "focus parent";
      "${mod}+i" = "focus child";
      "${mod}+a" = "layout tabbed";
      "${mod}+s" = "layout stacking";
      "${mod}+d" = "layout toggle split";
      "${mod}+f" = "fullscreen toggle";
      "${mod}+${mod2}+f" = "fullscreen toggle global";
      "${mod}+z" = "split none";
      "${mod}+v" = "split horizontal";
      "${mod}+c" = "split vertical";

      # Floats
      "${mod}+m" = "focus mode_toggle";
      "${mod}+${mod2}+m" = "floating toggle";
      "${mod}+u" = "scratchpad show";
      "${mod}+${mod2}+u" = "move scratchpad";

      # Notifications
      "${mod}+n" = invoke_notification;
      "${mod}+${mod2}+n" = dismiss_notification;
      "${mod}+Shift+n" = dismiss_all_notifications;

      # Screenshots
      "${mod}+p" = screenshot_mouse;
      "${mod}+${mod2}+p" = screenshot_focused_output;
      "${mod}+${mod3}+p" = screencast_mouse;
      "${mod}+${mod4}+p" = screencast_stop;

      # Moving focus
      "${mod}+${left}" = "focus left";
      "${mod}+${down}" = "focus down";
      "${mod}+${up}" = "focus up";
      "${mod}+${right}" = "focus right";

      # Moving windows
      "${mod}+${mod2}+${left}" = "move left 200 ppt";
      "${mod}+${mod2}+${down}" = "move down 200 ppt";
      "${mod}+${mod2}+${up}" = "move up 200 ppt";
      "${mod}+${mod2}+${right}" = "move right 200 ppt";
      "${mod}+${mod2}+tab" = "move workspace back_and_forth";
      "${mod}+${mod2}+c" = "move position cursor";

      # Moving workspaces
      "${mod}+${mod3}+${left}" = "move workspace to output left";
      "${mod}+${mod3}+${down}" = "move workspace to output down";
      "${mod}+${mod3}+${up}" = "move workspace to output up";
      "${mod}+${mod3}+${right}" = "move workspace to output right";

      # Resizing
      "${mod}+${mod4}+${left}" = "resize shrink width 50 px";
      "${mod}+${mod4}+${down}" = "resize shrink height 50 px";
      "${mod}+${mod4}+${up}" = "resize grow height 50 px";
      "${mod}+${mod4}+${right}" = "resize grow width 50 px";

      # Switching between workspaces
      "${mod}+tab" = "workspace back_and_forth";
      "${mod}+1" = "workspace 1:1";
      "${mod}+2" = "workspace 2:2";
      "${mod}+3" = "workspace 3:3";
      "${mod}+4" = "workspace 4:4";
      "${mod}+5" = "workspace 5:5";
      "${mod}+6" = "workspace 6:6";
      "${mod}+7" = "workspace 7:7";
      "${mod}+8" = "workspace 8:8";
      "${mod}+9" = "workspace 9:9";
      "${mod}+0" = "workspace 10:0";

      # Moving windows between workspaces
      "${mod}+${mod2}+1" = "move container to workspace 1:1";
      "${mod}+${mod2}+2" = "move container to workspace 2:2";
      "${mod}+${mod2}+3" = "move container to workspace 3:3";
      "${mod}+${mod2}+4" = "move container to workspace 4:4";
      "${mod}+${mod2}+5" = "move container to workspace 5:5";
      "${mod}+${mod2}+6" = "move container to workspace 6:6";
      "${mod}+${mod2}+7" = "move container to workspace 7:7";
      "${mod}+${mod2}+8" = "move container to workspace 8:8";
      "${mod}+${mod2}+9" = "move container to workspace 9:9";
      "${mod}+${mod2}+0" = "move container to workspace 10:0";

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
      "XF86Wlan" = wlan;
      "XF86Bluetooth" = bluetooth;
    };
  };
}
