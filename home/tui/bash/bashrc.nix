{ pkgs, ... }:
let
  undistract = # bash
    ''

      export UNDISTRACT_TOLERANCE=5

      __undistract_preexec() {
      	__undistract_last_command_start_time=$(date +%s)
      	__undistract_last_command="$1"
      }
      preexec_functions+=(__undistract_preexec)

      __undistract() {
      	[ -z "$__undistract_last_command_start_time" ] && return
      	local diff="$(($(date +%s) - __undistract_last_command_start_time))"
      	((diff > UNDISTRACT_TOLERANCE)) && [[ $TERM =~ ^(foot)$ ]] && {
      		tput bel
      		printf "\e]777;notify;%s;%s\e\\" "Executed" "$__undistract_last_command"
      	}
      	# 777: foot, ghostty
      	# 99: foot
      	# '\e]99;;%s\e\\'
      }
      precmd_functions+=(__undistract)
    '';

  template = # bash
    ''
      template() (
        path="$HOME/notes/templates/$1"
        [ -d "$path" ] || {
          echo "$path is not a directory"
        }
        shopt -s dotglob
        cp "$path"/* ./
      )
    '';

  reflake = # bash
    ''
      __jq_equals() {
        # checks if prop is equal in both jsons
        if [ "$#" -ne 3 ]; then
          echo 'error(usage): __jq_equals: not enough args'
          return 1
        fi
        local prop=$1
        local a=$2
        local b=$3

        local prop_a=$(jq -r "$prop | tojson" "$a")
        local match=$(jq -r --arg prop_a "$prop_a" "$prop == (\$prop_a | fromjson)" "$b")
        [ "$match" == true ]
      }
      reflake() {
        local target_file="$1"
        [ -z "$target_file" ] && target_file=./flake.lock

        local source_file="/etc/nixos/flake.lock"

        for file in "$source_file" "$target_file"; do
          [ -f "$file" ] || {
            echo "$file not found"
            return 1
          }
        done

        while IFS= read -r -d ''' input_name; do
          local input=".nodes.\"$input_name\""
          local lockProp="$input.locked"

          # skip inputs without lock
          local source_has_prop=$(jq -r "$lockProp != null" "$source_file")
          # NOTE indirect is deprecated
          local indirect=$(jq -r "$input.original.type == \"indirect\"" "$target_file")
          [ "$indirect" == true ] && echo 'warning: deprecated input type "indirect" found'
          if [ "$source_has_prop" == false ] || [ "$indirect" == true ]; then
            continue
          fi

          # make sure it's actually the same input (compare the sources)
          __jq_equals "$input.original" "$source_file" "$target_file" || {
            echo ".original mismatch on $input"
            return 1
          }

          # replace the lock
          local new_value=$(jq -r "$lockProp | tojson" "$source_file")
          local replace_expr="$lockProp = (\$arg | fromjson)"
          jq --arg arg "$new_value" "$replace_expr" "$target_file" | sponge "$target_file"
        done < <(jq --raw-output0 ".nodes | keys[]" "$target_file")

        echo "synced $target_file with system flake.lock"
      }
    '';

  pandoc =
    let
      extensions = "-f markdown+wikilinks_title_after_pipe+short_subsuperscripts+mark";
      preamble = ''-H "$XDG_CONFIG_HOME/latex/preamble.tex"'';
      # TODO replace notify-send
      popup_duration = 1000; # ms
      notify =
        text: duration: id:
        "notify-send ${if id == "" then "" else "-r ${id}"} ${
          if duration == "" then "" else "-t ${duration}"
        } -p $'\n\n${text}\n\n'";
      name = "pandoc-md";
      render =
        pkgs.writeShellScript name
          # bash
          ''
            [[ $# != 2 ]] && {
              echo "usage: $0 input.md output.pdf"
              exit 1
            }

            local id=$(${notify "rendering" "" ""})
            pandoc "$1" ${extensions} -t pdf -o "$2"
            ${notify "done" "$id" "1000"}
          '';
      # mark: ==highlighted text==
      # short_superscripts: x^2, O~2
      # alerts: > [!TIP] -- not supported for "markdown" yet, <https://github.com/jgm/pandoc/issues/9716>
      # even if they were, pdf output is ugly
      # --citeproc might be useful TODO document
      # also maybe switch to --pdf-engine xelatex
    in
    {
      hotdoc = # bash
        ''
          hotdoc() {
          	# renders $1.md to pdf, opens in zathura, rerenders on save
          	# usage: $0 $target
          	local -r md=$(realpath "$1")
          	local -r name=$(basename -s .md "$1")
            local -r pdf="$(mktemp --tmpdir "''${name}_XXXXXXXX.pdf")"
          	# initialize it with a basic pdf so that zathura doesn't shit itself
          	echo 'JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==' \
          		| base64 -d > "$pdf"
          	# trap interrupts to do the cleanup
          	trap 'echo trapped SIGINT' INT

          	# open zathura
          	nohup zathura "$pdf" &> /dev/null &
          	local -r zathura_pid="$!"

          	# start watching, recompile on change
          	local -r cmd=$(printf '${render} "%s" "%s"' "$md" "$pdf")
          	entr -rcsn "$cmd" < <(echo "$md") &
          	local -r entr_pid="$!"

          	# stop watching if zathura is closed
          	wait "$zathura_pid"
          	kill "$entr_pid"

          	echo cleaning...
          	rm "$pdf"
          }
        '';
      md =
        # bash
        ''
          pandoc-md() {
            ${render} "$@"
          }
        '';
    };
in
{
  programs.bash.bashrcExtra =
    # xdg shims should be here
    undistract
    + reflake
    + pandoc.hotdoc
    + pandoc.md
    + template
    +
      # bash
      ''
        source ${./xdg_shims.sh} # go through, verify, then move to env vars
        [[ $- == *i* ]] || return
        # WARN here order matters for sure
        source ${./git.sh}
        source ${./prompt.sh}

        source ${./bashrc.sh}

        # does this even work
        PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND;}history -a"
        source ${./osc.sh}
        source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
      '';
}
