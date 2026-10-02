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

  # prints the image protocol of the terminal: kitty, kitty-direct (no unicode placeholders) or sixels;
  # nothing for text blocks, or without a controlling tty (e.g. spawned by nvim)
  imageProtocol =
    pkgs.writeShellScript "image-protocol"
      # bash
      ''
        s=$(stty -g 2>/dev/null </dev/tty) || exit
        exec <>/dev/tty
        stty -echo -icanon
        # kitty graphics query, XTVERSION, then DA1:
        # every terminal answers DA1, so it marks the end of the replies
        printf '\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[>q\e[c' >&0
        until [[ $r =~ $'\e'\[\?([0-9\;]*)c$ ]]; do IFS= read -rN1 -t 0.5 c || break; r+=$c; done
        stty "$s"
        if [[ -z ''${BASH_REMATCH[0]} ]]; then
          echo "terminal didn't answer the image protocol query; previews will use text blocks" >&2
        elif [[ $r == *'_Gi=31;OK'* ]]; then
          # zellij answers for the terminals attached to it, and has no unicode placeholders
          [[ $r == *'>|Zellij('* ]] && echo kitty-direct || echo kitty
        elif [[ ";''${BASH_REMATCH[1]};" == *';4;'* ]]; then
          echo sixels
        fi
      '';

  preview =
    pkgs.writeShellScript "preview"
      # bash
      ''
        fmt=''${IMAGE_PROTOCOL:-symbols}

        # shows image from stdin; adapted from fzf's bin/fzf-preview.sh
        img() {
          local cols=$FZF_PREVIEW_COLUMNS rows=$FZF_PREVIEW_LINES mode=memory
          if [[ $fmt == kitty ]]; then
            # memory transfer is local only
            [[ -n $SSH_CONNECTION ]] && mode=stream
            # unicode placeholders get cleared/redrawn by fzf like text
            ${lib.getExe' pkgs.kitty.kitten "kitten"} icat --clear --scale-up --transfer-mode="$mode" --unicode-placeholder \
              --stdin=yes --place="''${cols}x$rows@0x0"
            return
          fi
          # sixel touching the bottom of the screen scrolls it: https://github.com/junegunn/fzf/issues/2544
          [[ $fmt == sixels ]] && ((FZF_PREVIEW_TOP + rows == $(stty size </dev/tty | cut -d' ' -f1))) && rows=$((rows - 1))
          # chafa reads the cell size in pixels from the controlling tty
          ${getExe pkgs.chafa} -f "''${fmt%-direct}" --scale max -s "''${cols}x$rows" -
        }

        # zellij has no unicode placeholders, so images are placed directly and have to be deleted by hand;
        # the rest get cleared when fzf's zellij popup pane closes
        [[ $fmt == kitty-direct ]] && printf '\e_Ga=d,d=A\e\\'

        # directory
        if [ -d "$1" ]; then
          ${eza} ${lib.strings.concatStringsSep " " config.programs.eza.extraOptions} --grid "$1"
          exit
        # file
        elif [ -f "$1" ]; then
          if [[ ''${1,,} == *.nef ]]; then
            # embedded jpeg: much faster than decoding raw; still slow, so cached by path and mtime;
            # written via a temp file, since fzf kills the preview mid-extraction on scroll
            c=''${XDG_CACHE_HOME:-$HOME/.cache}/fzf-preview/$({ realpath "$1"; stat -Lc %Y "$1"; } | md5sum | cut -d' ' -f1).jpg
            [ -s "$c" ] || { mkdir -p "''${c%/*}" && ${getExe pkgs.exiftool} -b -JpgFromRaw "$1" >"$c.$$" && mv "$c.$$" "$c"; }
            img <"$c" && exit
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
  home = {
    packages = [ fzsort ];
    sessionVariables = {
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
    shellAliases = {
      wget = "wget '--hsts-file=${config.xdg.dataHome}/wget-hsts'";
    };
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
      # the image protocol is queried at launch, since fzf owns the tty while previewing
      package = pkgs.symlinkJoin {
        inherit (pkgs.fzf) name version;
        meta.mainProgram = "fzf";
        paths = [
          pkgs.fzf
          pkgs.fzf.man
        ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/fzf --run 'export IMAGE_PROTOCOL=$(${imageProtocol})'";
      };
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
}
