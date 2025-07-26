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

  template = pkgs.writeShellApplication {
    name = "template";
    text = # bash
      ''
        main() (
          local root="$HOME/notes/templates"
          [ -z "$1" ] && ls root
          local path="$root/$1"
          [ -d "$path" ] || {
            echo "$path is not a directory"
          }
          shopt -s dotglob
          cp "$path"/* ./
        )
        main "$@"
      '';
  };

  reflake = pkgs.writeShellApplication {
    name = "reflake";
    runtimeInputs = with pkgs; [
      jq
      moreutils
    ];
    text = # bash
      ''
        __jq_equals() {
          # checks if prop is equal in both jsons
          local prop a b
          if [ "$#" -ne 3 ]; then
            echo 'error(usage): __jq_equals: not enough args'
            return 1
          fi
          prop=$1
          a=$2
          b=$3

          local prop_a match
          prop_a=$(jq -r "$prop | tojson" "$a")
          match=$(jq -r --arg prop_a "$prop_a" "$prop == (\$prop_a | fromjson)" "$b")
          [ "$match" == true ]
        }
        target_file="$1"
        [ -z "$target_file" ] && target_file=./flake.lock

        source_file="/etc/nixos/flake.lock"

        for file in "$source_file" "$target_file"; do
          [ -f "$file" ] || {
            echo "$file not found"
            return 1
          }
        done

        while IFS= read -r -d ''' input_name; do
          input=".nodes.\"$input_name\""
          lockProp="$input.locked"

          # skip inputs without lock
          source_has_prop=$(jq -r "$lockProp != null" "$source_file")
          # NOTE indirect is deprecated
          indirect=$(jq -r "$input.original.type == \"indirect\"" "$target_file")
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
          new_value=$(jq -r "$lockProp | tojson" "$source_file")
          replace_expr="$lockProp = (\$arg | fromjson)"
          jq --arg arg "$new_value" "$replace_expr" "$target_file" | sponge "$target_file"
        done < <(jq --raw-output0 ".nodes | keys[]" "$target_file")

        echo "synced $target_file with system flake.lock"
      '';
  };
  restack = pkgs.writeShellApplication {
    # runtimeInputs = with pkgs; [
    name = "restack";
    text = # bash
      ''
        find . -name stack.yaml -exec sed -i "s/^resolver:.*/resolver: $1/" {} \;
      '';
  };
in
{
  home.packages = [
    restack
    reflake
    template
  ];
  programs.bash.bashrcExtra =
    # xdg shims should be here
    undistract
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
