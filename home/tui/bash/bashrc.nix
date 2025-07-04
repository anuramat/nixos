{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) getExe;
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
in
{
  programs.bash.bashrcExtra =
    # xdg shims should be here
    undistract
    + reflake
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
