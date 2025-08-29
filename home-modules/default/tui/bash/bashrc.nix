{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) getExe;
  excludeShellChecks = map (v: "SC" + toString v) config.lib.excludeShellChecks.numbers;
  
  template = pkgs.writeShellApplication {
    name = "template";
    inherit excludeShellChecks;
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
    inherit excludeShellChecks;
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
    name = "restack";
    inherit excludeShellChecks;
    text = # bash
      ''
        find . -name stack.yaml -exec sed -i "s/^resolver:.*/resolver: $1/" {} \;
      '';
  };

  ghooks = pkgs.writeShellApplication {
    name = "ghooks";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      ghq
    ];
    text = # bash
      ''
        # lists hooks in ghq repos
        find "$(ghq root)" -wholename '*/.git/hooks/*' -not -name '*.sample'
      '';
  };

  gcreate = pkgs.writeShellApplication {
    name = "gcreate";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      ghq
      gh
      git
    ];
    text = # bash
      ''
        # creates and clones a repo with minimum amount of gh features turned on
        # $1 - name
        # $2? - public|private
        name=$1
        visibility=private
        [ "$2" != "" ] && visibility=$2
        case "$2" in
          private | public) ;;
          *) return 1 ;;
        esac

        path=$(ghq create "$name") || return 1
        cd "$path" || return 1
        git commit --allow-empty -m "init"
        gh repo create "--$visibility" --disable-issues --disable-wiki --push --source "$path"
        gh repo set-default
        gh repo edit --enable-projects=false
      '';
  };

  gfork = pkgs.writeShellApplication {
    name = "gfork";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      gh
      gnugrep
      coreutils
      ghq
    ];
    text = # bash
      ''
        # $1 - repo to fork
        repo="$1"
        auth_output=$(gh auth status --active) || return 1
        user=$(grep -oP 'account \K\S+' <<<"$auth_output")
        
        # cd to GitHub owner directory
        path="$(ghq root)/github.com/$user"
        mkdir -p "$path" || return 1
        cd "$path" || return 1
        
        gh repo fork "$repo" --default-branch-only --clone
        cd "$(basename "''${repo%/}")" || return 1
      '';
  };

  zoxide-add-ghq = pkgs.writeShellApplication {
    name = "zoxide-add-ghq";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      ghq
      zoxide
      findutils
    ];
    text = # bash
      ''
        # add all ghq repos to zoxide
        find "$(ghq root)" -maxdepth 3 -mindepth 3 -print0 | xargs -0 zoxide add
      '';
  };

  grm = pkgs.writeShellApplication {
    name = "grm";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      ghq
      fzf
      bash
    ];
    text = # bash
      ''
        # $1? - prefill query
        gitgud_picker() {
          # pick a subset of a list with confirmation
          # stdin - NL separated list
          # $1? - prompt question (empty |-> auto-accept)
          # $2? - prefill query
          # stdout - NL separated list
          local repos
          repos="$(fzf -1 -q "$2")" || return 1
          echo "$repos"
          echo $'\t'"''${repos//$'\n'/$'\n\t'}" >&2

          [ "$1" = "" ] && return

          read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
          [ "$choice" = 'y' ]
        }

        selected=$(ghq list | gitgud_picker "delete?" "$1") || return
        xargs -I{} bash -c 'yes | ghq rm {} 2>/dev/null' <<<"$selected"
      '';
  };

  gclone = pkgs.writeShellApplication {
    name = "gclone";
    inherit excludeShellChecks;
    runtimeInputs = with pkgs; [
      gh
      ghq
      fzf
      jq
      coreutils
    ];
    text = # bash
      ''
        # $1? - a single repo name
        repos=$1

        gitgud_picker() {
          # pick a subset of a list with confirmation
          # stdin - NL separated list
          # $1? - prompt question (empty |-> auto-accept)
          # $2? - prefill query
          # stdout - NL separated list
          local repos
          repos="$(fzf -1 -q "$2")" || return 1
          echo "$repos"
          echo $'\t'"''${repos//$'\n'/$'\n\t'}" >&2

          [ "$1" = "" ] && return

          read -rs -n 1 -p $"$1 (y/*):"$'\n' choice <&2
          [ "$choice" = 'y' ]
        }

        cd_gh_owner() {
          local path="$(ghq root)/github.com/$1"
          mkdir -p "$path" || return 1
          cd "$path" || return 1
        }

        # no repo name? open picker
        [ "$repos" = "" ] && {
          repos=$(gh repo list | cut -f 1 | gitgud_picker "") || {
            echo "Selection cancelled"
            return
          }
        }

        for repo in ''${repos[@]}; do
          owner=$(gh repo view "$repo" --json owner --jq '.owner.login') || return 1
          cd_gh_owner "$owner" || return 1
          gh repo clone "$repo"
        done
        cd "$(basename "''${repo%/}")" || return 1
      '';
  };
in
{
  home.packages = [
    restack
    reflake
    template
    ghooks
    gcreate
    gfork
    zoxide-add-ghq
    grm
    gclone
  ];
  programs.bash.bashrcExtra =
    # bash
    ''
      source ${./xdg_shims.sh} # TODO go through, verify, then move to env vars
      [[ $- == *i* ]] || return
      # WARN here order matters for sure
      source ${./git-functions.sh}

      source ${./bashrc.sh}

      shopt -s globstar # enables **
      set +H            # turn off ! history bullshit

      # TODO does this even work/is this required
      PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND;}history -a"
      source ${./osc.sh}
    '';
}
