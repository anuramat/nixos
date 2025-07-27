{
  pkgs,
  config,
  ...
}:
let
  hotdoc = pkgs.writeShellApplication {
    name = "hotdoc";
    runtimeInputs =
      (with pkgs; [
        entr
        zathura
      ])
      ++ [ render ];
    text =
      let
        pdfPlaceholder = "JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==";
      in
      # bash
      ''
        main() {
          	# renders $1.md to pdf, opens in zathura, rerenders on save
          	# usage: $0 $target
          	md=$(realpath "$1")
          	name=$(basename -s .md "$1")
            shift
            pdf="$(mktemp --tmpdir "$name-XXXXXXXX.pdf")"

          	# initialize it with a basic pdf so that zathura doesn't shit itself
          	echo '${pdfPlaceholder}' | base64 -d > "$pdf"

          	# open zathura
          	nohup zathura "$pdf" &> /dev/null &
          	zathura_pid="$!"

          	# start watching, recompile on change
          	cmd="render $(printf "'%s' " "$md" "$pdf" "$@")"
          	entr -rcsn "$cmd" < <(echo "$md") &
          	entr_pid="$!"

          	# stop watching if zathura is closed
          	wait "$zathura_pid"
          	kill "$entr_pid"
          }
          main "$@" &>/dev/null & disown
      '';
  };
  render = pkgs.writeShellApplication {
    name = "render";
    runtimeInputs = with pkgs; [
      texliveFull
      pandoc
      libnotify
      # somehow add "collect"
    ];
    text =
      let
        preamblePath = "${config.xdg.configHome}/latex/preamble.tex";
        popupDuration = "1000"; # ms
        inputFormat = "markdown+wikilinks_title_after_pipe+mark";
        # mark: ==highlighted text==
      in
      # bash
      ''
        (( $# < 2 )) && {
          echo "usage: $0 input.md output.pdf [args...]"
          exit 1
        }
        input=$1 && shift
        output=$1 && shift

        id=$(notify-send -p "rendering")
        fullPreamble=$(mktemp)
        cat ${preamblePath} > "$fullPreamble"
        collect .preamble.tex >> "$fullPreamble"
        if log=$(pandoc "$input" -o "$output" -f ${inputFormat} -H "$fullPreamble" "$@" 2>&1); then
          notify-send -r "$id" -t ${popupDuration} "render ok"
        else
          notify-send -r "$id" -u critical "render error" "$log"
          echo "$log" >&2
          exit 1
        fi
      '';
  };
in
{
  home.packages = [
    render
    hotdoc
  ];
}
