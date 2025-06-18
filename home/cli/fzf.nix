{
  lib,
  config,
  pkgs,
  ...
}:
let
  eza = "${config.programs.eza.package}/bin/eza";
  timg = "${pkgs.timg}/bin/timg";
  bat = "${pkgs.bat}/bin/bat";
in
{
  programs.fzf =
    let
      preview =
        pkgs.writeShellScript "fzf_preview"
          # bash
          ''
            # directory
            if [ -d "$1" ]; then
              ${eza} ${lib.strings.concatStringsSep " " config.programs.eza.extraOptions} --grid "$1"
              exit
            # file
            elif [ -f "$1" ]; then
            	${timg} -p s "-g''${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES" "$1" && exit
              ${bat} --style=numbers --color=always "$1" && exit
            fi
          '';
      fd = "fd -u --exclude .git/";
    in
    {
      enable = true;
      defaultCommand = fd;

      changeDirWidgetCommand = "${fd} -t d";
      # changeDirWidgetOptions = "$default_preview";
      # fileWidgetCommand = "$FZF_DEFAULT_COMMAND";
      # fileWidgetOptions = "$default_preview";

      defaultOptions = [
        "--layout=reverse"
        "--keep-right"
        "--info=inline"
        "--tabstop=2"
        "--multi"
        "--height=50%"

        "--tmux=center,90%,80%"

        "--bind='ctrl-/:change-preview-window(down|hidden|)'"
        "--bind='ctrl-j:accept'"
        "--bind='tab:toggle+down'"
        "--bind='btab:toggle+up'"

        "--bind='ctrl-y:preview-up'"
        "--bind='ctrl-e:preview-down'"
        "--bind='ctrl-u:preview-half-page-up'"
        "--bind='ctrl-d:preview-half-page-down'"
        "--bind='ctrl-b:preview-page-up'"
        "--bind='ctrl-f:preview-page-down'"

        "--preview='${preview} {}'"
      ];
    };
}
