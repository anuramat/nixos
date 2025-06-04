{ }:
let
  # Terminal commands
  term = "foot";
  term_float = "foot -a foot-float -W 88x28";

  # Menu and applications
  menu = "bemenu";
  bookdir = "~/books";
  books = "pkill bemenu || swaymsg exec \"echo \\\"$(cd $bookdir && fd -t f | $menu -p read -l 20)\\\" | xargs -rI{} zathura '$bookdir/{}'\"";
  drun = "pkill bemenu || swaymsg exec \"$(j4-dmenu-desktop -d '$menu -p drun' -t $term -x --no-generic)\"";
  todo_add = "pkill bemenu || swaymsg exec \"$(echo '' | $menu -p task -l 0 | xargs -I{} todo add \\\"{}\\\")\"";
  todo_done = "pkill bemenu || swaymsg exec \"$(todo ls | tac | $menu -p done | sed 's/^\\s*//' | cut -d ' ' -f 1 | xargs todo rm)\"";
  lock = "loginctl lock-session";

  # Notifications
  invoke_notification = "makoctl invoke";
  dismiss_notification = "makoctl dismiss";
  dismiss_all_notifications = "makoctl dismiss --all";

  # Screenshots
  screenshot_mouse = "swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | slurp | xargs -I {} grim -g \"{}\" - | swappy -f -";
  screenshot_focused_window = "swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.focused) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | xargs -I {} grim -g \"{}\" - | swappy -f -";
  screenshot_all_outputs = "grim - | swappy -f -";
  screenshot_focused_output = "grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') - | swappy -f -";

  # Screencasting
  screencast_mouse = "swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | slurp | xargs -I {} wf-recorder -g \"{}\" -f \"~/vid/screen/$(date +%Y-%m-%d_%H-%M-%S).mp4\"";
  screencast_stop = "killall wf-recorder";

  # Special keys - brightness
  brightness =
    let
      l = v: "lightctl ${v}";
    in
    {
      up = l "up";
      down = l "down";
    };

  # Special keys - sound
  sound =
    let
      l = v: "volumectl ${v}";
    in
    {
      up = "-u up";
      down = "-u down";
      mute = "toggle-mute";
      muteMic = "-m toggle-mute";
    };

  # Special keys - audio control
  audio =
    let
      l = v: "playerctl -p spotify ${v}";
    in
    {
      prev = l "previous";
      next = l "next";
      playPause = l "play-pause";
      stop = l "stop";
    };

  # Special keys - toggles
  wlan = "wifi toggle";
  bluetooth = "bluetooth toggle";
in
{

}
