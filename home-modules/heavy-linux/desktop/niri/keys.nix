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
        l = v: "${pkgs.avizo}/bin/lightctl ${v}";
      in
      {
        up = l "up";
        down = l "down";
      };
    sound =
      let
        l = v: "${pkgs.avizo}/bin/volumectl ${v}";
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
        l = v: "${pkgs.playerctl}/bin/playerctl ${v}";
      in
      {
        prev = l "previous";
        next = l "next";
        playPause = l "play-pause";
        stop = l "stop";
      };
    bluetooth = "${pkgs.tlp}/bin/bluetooth toggle";
    lock = "loginctl lock-session";
    sleep = "systemctl suspend";
    wlan = "${pkgs.tlp}/bin/wifi toggle";
  };

  term_cmd = "${config.home.sessionVariables.TERMCMD}";

  pickers =
    let
      j4 = getExe pkgs.j4-dmenu-desktop;
      pkill = "${pkgs.procps}/bin/pkill";
      todo = getExe pkgs.todo;
      fd = getExe pkgs.fd;
      zathura = getExe pkgs.zathura;
      bemenu = getExe pkgs.bemenu;

      mkMenu =
        command:
        pkgs.writeShellScript "mkmenu" ''
          if ${pkill} -x bemenu; then
            exit 0
          fi
          ${command}
        '';
    in
    {
      books =
        mkMenu
          # bash
          ''
            cd ${bookdir}
            book=$(${fd} . "${bookdir}" -at f | ${bemenu} -p read -l 20) || exit
            ${zathura} $book
          '';
      drun =
        mkMenu
          # bash
          ''
            "$(${j4} -d '${bemenu} -p drun' -t '${term_cmd}' -x --no-generic)"
          '';
      todo_add =
        mkMenu
          # bash
          ''
            task=$(echo "" | ${bemenu} -p todo -l 0) || exit
            ${todo} add "$task"
          '';
      todo_done =
        mkMenu
          # bash
          ''
            task=$(${todo} ls | tac | ${bemenu} -p done) || exit
            task_id=$(echo "$task" | sed 's/^\s*//' | cut -d ' ' -f 1)
            ${todo} rm "$task_id"
          '';
    };

  notifications =
    let
      makoctl = "${pkgs.mako}/bin/makoctl";
    in
    {
      invoke = "${makoctl} invoke";
      dismiss = "${makoctl} dismiss";
      dismiss_all = "${makoctl} dismiss --all";
    };

  # TODO markup screenshots

in

{
  programs.niri.settings.binds = {
    "Mod+semicolon".action.spawn = "foot";
  };
}
