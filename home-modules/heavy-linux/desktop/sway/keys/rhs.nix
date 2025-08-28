{
  lib,
  config,
  pkgs,
  hax,
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
  term = "exec ${term_cmd}";

  pickers =
    let
      j4 = getExe pkgs.j4-dmenu-desktop;
      pkill = "${pkgs.procps}/bin/pkill";
      todo = "todo";
      fd = getExe pkgs.fd;
      zathura = getExe pkgs.zathura;
      bemenu = getExe pkgs.bemenu;
    in
    {
      books = ''exec ${pkill} -f ^${bemenu} || swaymsg exec "echo \"$(cd ${bookdir} && ${fd} -t f | ${bemenu} -p read -l 20)\" | xargs -rI{} ${zathura} '${bookdir}/{}'"'';
      drun = ''exec ${pkill} -f ^${bemenu} || swaymsg exec "$(${j4} -d '${bemenu} -p drun' -t ${term_cmd} -x --no-generic)"'';
      todo_add = ''exec ${pkill} -f ^${bemenu} || swaymsg exec "$(echo ''' | ${bemenu} -p ${todo} -l 0 | xargs -I{} ${todo} add \"{}\")"'';
      todo_done = ''exec ${pkill} -f ^${bemenu} || swaymsg exec "$(${todo} ls | tac | ${bemenu} -p done | sed 's/^\s*//' | cut -d ' ' -f 1 | xargs ${todo} rm)"'';
    };

  screen =
    let
      grim = getExe pkgs.grim;
      jq = getExe pkgs.jq;
      slurp = getExe pkgs.slurp;
    in
    {
      # TODO move giant oneliners to scripts
      shot =
        let
          swappy = getExe pkgs.swappy;
        in
        {
          selection = "exec swaymsg -t get_tree | ${jq} -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${grim} -g \"{}\" - | ${swappy} -f -";
          focused.output = "exec ${grim} -o $(swaymsg -t get_outputs | ${jq} -r '.[] | select(.focused) | .name') - | ${swappy} -f -";
        };
      cast.selection =
        let
          wf-recorder = getExe pkgs.wf-recorder;
          pkill = "${pkgs.procps}/bin/pkill";
        in
        "exec ${pkill} -INT -x wf-recorder || swaymsg -t get_tree | ${jq} -r '.. | (.nodes? // empty)[] | select(.pid and .visible) | .rect | \"\\(.x),\\(.y) \\(.width)x\\(.height)\"' | ${slurp} | xargs -I {} ${wf-recorder} -g \"{}\" -f \"${config.home.sessionVariables.XDG_VIDEOS_DIR}/screen/$(date +%Y-%m-%d_%H-%M-%S).mp4\"";
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

  cycle =
    let
      jq_expr = hax.common.join ''
        sort_by(.name) as $outs | $outs |
        map(.focused) | index(true) |
        if . == ($outs | length) - 1 then $outs[0] else $outs[. + 1] end |
        .name
      '';
      next_output = "$(swaymsg -t get_outputs | ${getExe pkgs.jq} -r '${jq_expr}')";
    in
    {
      focus = "exec swaymsg focus output ${next_output}";
      move = "exec swaymsg move output ${next_output}";
    };
in
{
  inherit
    term
    screen
    pickers
    notifications
    ctl
    cycle
    ;
}
