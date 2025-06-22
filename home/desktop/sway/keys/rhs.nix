{
  lib,
  config,
  pkgs,
  ...
}:
let
  bookdir = "${config.home.homeDirectory}/books";

  inherit (lib) getExe;

  ctl = {
    brightness =
      let
        l = v: "exec ${pkgs.avizo}/bin/lightctl ${v}";
      in
      {
        up = l "up";
        down = l "down";
      };
    sound =
      let
        l = v: "exec ${pkgs.avizo}/bin/volumectl ${v}";
      in
      {
        up = l "-u up";
        down = l "-u down";
        mute = l "toggle-mute";
        muteMic = l "-m toggle-mute";
      };
    playback =
      let
        l = v: "exec ${pkgs.playerctl}/bin/playerctl -p spotify ${v}";
      in
      {
        prev = l "previous";
        next = l "next";
        playPause = l "play-pause";
        stop = l "stop";
      };
    bluetooth = "exec ${pkgs.tlp}/bin/bluetooth toggle";
    lock = "exec loginctl lock-session";
    sleep = "exec systemctl suspend";
    wlan = "exec ${pkgs.tlp}/bin/wifi toggle";
  };

  term_cmd = getExe pkgs.foot;
  term = rec {
    exec = "exec ${term_cmd}";
    float = "${exec} -a foot-float -W 88x28";
  };

  pickers =
    let
      j4 = getExe pkgs.j4-dmenu-desktop;
      killall = getExe pkgs.killall;
      todo = "todo";
      fd = getExe pkgs.fd;
      zathura = getExe pkgs.zathura;
      bemenu = getExe pkgs.bemenu;
    in
    {
      books = ''exec ${killall} ${bemenu} || swaymsg exec "echo \"$(cd ${bookdir} && ${fd} -t f | ${bemenu} -p read -l 20)\" | xargs -rI{} ${zathura} '${bookdir}/{}'"'';
      drun = ''exec ${killall} ${bemenu} || swaymsg exec "$(${j4} -d '${bemenu} -p drun' -t ${term_cmd} -x --no-generic)"'';
      todo_add = ''exec ${killall} ${bemenu} || swaymsg exec "$(echo ''' | ${bemenu} -p ${todo} -l 0 | xargs -I{} ${todo} add \"{}\")"'';
      todo_done = ''exec ${killall} ${bemenu} || swaymsg exec "$(${todo} ls | tac | ${bemenu} -p done | sed 's/^\s*//' | cut -d ' ' -f 1 | xargs ${todo} rm)"'';
    };

  screen =
    let
      grim = getExe pkgs.grim;
      jq = getExe pkgs.jq;
      slurp = getExe pkgs.slurp;
    in
    {
      shot =
        let
          swappy = getExe pkgs.swappy;
        in
        {
          selection = "exec swaymsg -t get_tree | jq -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${grim} -g \"{}\" - | ${swappy} -f -";
          focused.output = "exec ${grim} -o $(swaymsg -t get_outputs | ${jq} -r '.[] | select(.focused) | .name') - | ${swappy} -f -";
        };
      cast.selection =
        let
          wf-recorder = getExe pkgs.wf-recorder;
        in
        "exec swaymsg -t get_tree | ${jq} -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${wf-recorder} -g \"{}\" -f \"~/vid/screen/$(date +%Y-%m-%d_%H-%M-%S).mp4\"";
    };

  notifications =
    let
      makoctl = "${pkgs.mako}/bin/makoctl";
    in
    {
      invoke = "exec ${makoctl} invoke";
      dismiss = "exec ${makoctl} dismiss";
      dismiss_all = "exec ${makoctl} dismiss --all";
    };

  float_notes = "${term.float} --working-directory=\"$HOME/notes\" -e bash $EDITOR ~/notes/scratchpad.md";
in
{
  inherit
    float_notes
    term
    screen
    pickers
    notifications
    ctl
    ;
}
