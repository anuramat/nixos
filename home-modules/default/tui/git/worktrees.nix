{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gwt";
      text = ''
        if [ $# -ne 1 ]; then
          echo "Usage: gwt <worktree-name>"
          exit 1
        fi

        reponame=$(basename "$(git rev-parse --show-toplevel)")
        worktree_path="''${XDG_DATA_HOME:-$HOME/.local/share}/git/worktrees/$reponame/$1"

        mkdir -p "$(dirname "$worktree_path")"
        git worktree add "$worktree_path"
      '';
    })
  ];
}
