{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gwt";
      runtimeInputs = [ pkgs.gum ];
      text = ''
        if [ $# -eq 0 ]; then
          worktree_name=$(gum input --placeholder "Enter worktree name")
          if [ -z "$worktree_name" ]; then
            echo "No worktree name provided"
            exit 1
          fi
        elif [ $# -eq 1 ]; then
          worktree_name="$1"
        else
          echo "Usage: gwt [worktree-name]"
          exit 1
        fi

        reponame=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")")
        worktree_path="''${XDG_DATA_HOME:-$HOME/.local/share}/git/worktrees/$reponame/$worktree_name"

        mkdir -p "$(dirname "$worktree_path")"
        git worktree add "$worktree_path"
      '';
    })
  ];
}
