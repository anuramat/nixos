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

  # zellij hides which terminal is attached, so the one it was last started from records it here
  zellijHost = "$XDG_RUNTIME_DIR/zellij-host-image-protocol";

  preview =
    pkgs.writeShellScript "preview"
      # bash
      ''
        fmt=''${IMAGE_PROTOCOL:-symbols} cell=$IMAGE_CELL zellij=
        if [[ $fmt == zellij ]]; then
          zellij=1 fmt=symbols
          read -r fmt cell 2>/dev/null <"${zellijHost}"
        fi

        # shows image from stdin; adapted from fzf's bin/fzf-preview.sh
        img() {
          local cols=$FZF_PREVIEW_COLUMNS rows=$FZF_PREVIEW_LINES mode=memory
          if [[ $fmt == kitty && -z $zellij ]]; then
            # memory transfer is local only
            [[ -n $SSH_CONNECTION ]] && mode=stream
            # unicode placeholders get cleared/redrawn by fzf like text; trailing reset line confuses fzf
            ${lib.getExe' pkgs.kitty.kitten "kitten"} icat --clear --scale-up --transfer-mode="$mode" --unicode-placeholder \
              --stdin=yes --place="''${cols}x$rows@0x0" | sed '$d' | sed $'$s/$/\e[m/'
            return
          fi
          if [[ $fmt == sixels ]]; then
            # sixel touching the bottom of the screen scrolls it: https://github.com/junegunn/fzf/issues/2544
            ((FZF_PREVIEW_TOP + rows == $(stty size </dev/tty | cut -d' ' -f1))) && rows=$((rows - 1))
            # chafa can't query the cell size in a pipe and assumes 10x20px, so the size is converted;
            # one column less, since it overshoots by a few pixels
            [[ $cell =~ ^([0-9]+)x([0-9]+)$ ]] && cols=$((cols * BASH_REMATCH[1] / 10 - 1)) rows=$((rows * BASH_REMATCH[2] / 20))
          fi
          ${getExe pkgs.chafa} -f "$fmt" --scale max -s "''${cols}x$rows" -
        }

        # zellij has no unicode placeholders, so images are placed directly and have to be deleted by hand;
        # the rest get cleared when fzf's zellij popup pane closes
        [[ -n $zellij && $fmt == kitty ]] && printf '\e_Ga=d,d=A\e\\'

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
  # probed on shell startup, since fzf owns the tty while previewing
  programs.bash.initExtra = # bash
    ''
      IMAGE_PROTOCOL=symbols IMAGE_CELL=
      # kitty graphics query, XTVERSION, cell size in pixels, then DA1:
      # every terminal answers DA1, so it marks the end of the replies
      if __s=$(stty -g 2>/dev/null) && stty -echo -icanon; then
        printf '\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[>q\e[16t\e[c'
        __r=
        until [[ $__r =~ $'\e'\[\?([0-9\;]*)c$ ]]; do IFS= read -rN1 -t 0.5 __c || break; __r+=$__c; done
        stty "$__s"
        if [[ -z ''${BASH_REMATCH[0]} ]]; then
          echo "terminal didn't answer the image protocol query; fzf previews will use text blocks" >&2
        elif [[ $__r == *'>|Zellij('* ]]; then
          IMAGE_PROTOCOL=zellij
        elif [[ $__r == *'_Gi=31;OK'* ]]; then
          IMAGE_PROTOCOL=kitty
        elif [[ ";''${BASH_REMATCH[1]};" == *';4;'* ]]; then
          IMAGE_PROTOCOL=sixels
        fi
        [[ $__r =~ $'\e'\[6\;([0-9]+)\;([0-9]+)t ]] && IMAGE_CELL=''${BASH_REMATCH[2]}x''${BASH_REMATCH[1]}
      fi
      export IMAGE_PROTOCOL IMAGE_CELL
      unset __s __r __c

      zellij() {
        [[ -z $ZELLIJ ]] && echo "$IMAGE_PROTOCOL $IMAGE_CELL" >"${zellijHost}"
        command zellij "$@"
      }
    '';

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
