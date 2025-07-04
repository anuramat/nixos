{
  pkgs,
  lib,
  config,
  ...
}:
let
  # TODO --citeproc?
  # TODO maybe switch to --pdf-engine xelatex
  inputFormat = "markdown+wikilinks_title_after_pipe+mark";
  # mark: ==highlighted text==
  preamblePath = "${config.xdg.configHome}/latex/preamble.tex";
  # TODO replace notify-send with a proper ref from store
  inherit (lib) getExe;
  zathura = getExe pkgs.zathura;
  entr = getExe pkgs.entr;
  popupDuration = 1000; # ms
  notify =
    text: duration: id:
    "${pkgs.libnotify}/bin/notify-send ${if id == "" then "" else "-r ${id}"} ${
      if duration <= 0 then "" else "-t ${toString duration}"
    } -p ${text}";
  pdfPlaceholder = "JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==";
  hotdoc =
    pkgs.writeShellScriptBin "hotdoc"
      # bash
      ''
        	# renders $1.md to pdf, opens in zathura, rerenders on save
        	# usage: $0 $target
        	md=$(realpath "$1")
        	name=$(basename -s .md "$1")
          shift
          pdf="$(mktemp --tmpdir "$name-XXXXXXXX.pdf")"

        	# initialize it with a basic pdf so that zathura doesn't shit itself
        	echo '${pdfPlaceholder}' | base64 -d > "$pdf"

        	# open zathura
        	nohup ${zathura} "$pdf" &> /dev/null &
        	zathura_pid="$!"

        	# start watching, recompile on change
        	cmd="${render} $(printf "'%s' " "$md" "$pdf" "$@")"
        	${entr} -rcsn "$cmd" < <(echo "$md") &
        	entr_pid="$!"

        	# stop watching if zathura is closed
        	wait "$zathura_pid"
        	kill "$entr_pid"
      '';
  render =
    pkgs.writeShellScriptBin "render"
      # bash
      ''
        (( $# < 2 )) && {
          echo "usage: $0 input.md output.pdf [args...]"
          exit 1
        }

        id=$(${notify "rendering" 0 ""})
        input=$1 && shift
        output=$1 && shift
        if log=$(${getExe pkgs.pandoc} "$input" -o "$output" -f ${inputFormat} -H ${preamblePath} "$@" 2>&1); then
          ${notify "done" popupDuration "$id"}
        else
          ${notify ''"$log"'' 0 "$id"}
        fi
      '';
in
{
  home.packages = [
    render
    hotdoc
  ];
}
