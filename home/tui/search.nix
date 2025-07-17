{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  eza = getExe config.programs.eza.package;
  fd = getExe config.programs.fd.package;
  bat = getExe config.programs.bat.package;

  preview =
    pkgs.writeShellScript "preview"
      # bash
      ''
        # directory
        if [ -d "$1" ]; then
          ${eza} ${lib.strings.concatStringsSep " " config.programs.eza.extraOptions} --grid "$1"
          exit
        # file
        elif [ -f "$1" ]; then
        	${getExe pkgs.timg} -p s "-g''${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES" "$1" && exit
          ${bat} --style=numbers --color=always "$1" && exit
        fi
      '';
  ignores = [ "**/.git/" ]; # hidden
  rgIgnores = [ "*.lock" ]; # non human readable, but visible
in
{

  home.sessionVariables = {
    _ZO_FZF_OPTS = lib.strings.concatStringsSep " " [
      "--no-sort"
      "--exit-0"
      "--select-1"
      "--preview='${preview} {2..}'"
    ];
    _ZO_RESOLVE_SYMLINKS = 1;
    _ZO_ECHO = 1;
    _ZO_EXCLUDE_DIRS = "${config.xdg.cacheHome}/*:${config.xdg.stateHome}:/nix/store/*";
  };
  programs = {
    ripgrep = {
      enable = true;
      arguments =
        let
          mkGlob = globExp: "--glob=!${globExp}";
        in
        [
          "--smart-case"
          "--hidden"
          "--follow"
        ]
        ++ (map mkGlob (ignores ++ rgIgnores));
    };

    ripgrep-all = {
      enable = true;
    };

    fzf = {
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

    zoxide = {
      enable = true;
      options = [
        "--cmd j"
      ];
    };

    fd = {
      enable = true;
      hidden = true;
      extraOptions = [ "--follow" ];
      inherit ignores;
    };
  };
  # TODO shouldn't be here
  home.shellAliases = {
    wget = "wget '--hsts-file=${config.xdg.dataHome}/wget-hsts'";
  };
}
