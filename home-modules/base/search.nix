{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  eza = getExe config.programs.eza.package;
  fd = "${getExe config.programs.fd.package} -HL"; # still respects the ignore files
  bat = getExe config.programs.bat.package;

  preview =
    pkgs.writeShellScript "preview"
      # bash
      ''
        # shows image from stdin; adapted from fzf's bin/fzf-preview.sh
        img() {
          local dim=''${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES
          if [[ -n $KITTY_WINDOW_ID || -n $GHOSTTY_RESOURCES_DIR ]] && command -v kitten >/dev/null; then
            # unicode placeholders get cleared/redrawn by fzf like text; trailing reset line confuses fzf
            kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=yes --place="$dim@0x0" | sed '$d' | sed $'$s/$/\e[m/'
          else
            # forced, since chafa can't detect sixel support in tmux without probing
            ${getExe pkgs.chafa} -f sixels -s "$dim" -
          fi
        }

        # directory
        if [ -d "$1" ]; then
          ${eza} ${lib.strings.concatStringsSep " " config.programs.eza.extraOptions} --grid "$1"
          exit
        # file
        elif [ -f "$1" ]; then
          if [[ ''${1,,} == *.nef ]]; then
            # embedded jpeg: much faster than decoding raw
            ${getExe pkgs.exiftool} -b -JpgFromRaw "$1" | img && exit
          else
            case $(${getExe pkgs.file} -bL --mime-type "$1") in
              image/*) img <"$1" ;;
              video/*) ${getExe pkgs.ffmpeg-headless} -v error -i "$1" -frames:v 1 -c:v png -f image2pipe - | img ;;
              application/pdf) ${lib.getExe' pkgs.poppler-utils "pdftoppm"} -png -singlefile -scale-to 1024 "$1" | img ;;
              *) false ;;
            esac && exit
          fi
          ${bat} --style=numbers --color=always "$1" && exit
        fi
      '';
  # usage: fzsort 'stat -c %s "$1"'; shows files in cwd, natural-sorted by the command output
  fzsort = pkgs.writeShellApplication {
    name = "fzsort";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    excludeShellChecks = [ "SC2016" ]; # single-quoted bash -c snippet
    text = ''
      line() {
        local f=''${1#./} key
        key=$(bash -c "$FZSORT_CMD" _ "$f" 2>/dev/null) || key='sort expr error'
        # single short write, so lines from parallel workers don't interleave
        printf '%s\t%s\n' "''${key//[$'\n\t']/ }" "$f"
      }
      export -f line
      export FZSORT_CMD=$1
      find . -mindepth 1 -maxdepth 1 ! -name '.*' -print0 |
        xargs -0 -n 1 -P "$(nproc)" bash -c 'line "$1"' _ |
        sort -t $'\t' -k1,1V | fzf --delimiter='\t' --accept-nth=2 --preview='${preview} {2}'
    '';
  };
  ignores = [ "**/.git/" ]; # hidden
  rgIgnores = [ "*.lock" ]; # non human readable, but visible
in
{
  home.packages = [ fzsort ];

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
      inherit ignores;
    };
  };

  home.shellAliases = {
    wget = "wget '--hsts-file=${config.xdg.dataHome}/wget-hsts'";
  };
}
