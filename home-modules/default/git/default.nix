{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./difft.nix
    ./ignores.nix
    ./jupyter.nix
    ./worktrees.nix
  ];

  home.sessionVariables.GHQ_ROOT = "${config.xdg.dataHome}/ghq";
  programs = {
    lazygit = {
      enable = true;
    };
    gh = {
      enable = true;
      settings = {
        aliases = {
          login = "auth login --skip-ssh-key --hostname github.com --git-protocol ssh --web";
          push = "repo create --disable-issues --disable-wiki --public --source=.";
        };
        extensions = with pkgs; [
          gh-f
          gh-copilot
        ];
        git_protocol = "ssh";
        prompt = true;
      };
    };

    git = {
      enable = true;

      aliases = {
        sw = "switch";
        ch = "checkout";
        wt = "worktree";
        st = "status";
        sh = "show --ext-diff";
        cm = "!git add -A && git commit";
        lp = "log --ext-diff -p";
        lg = "log --ext-diff --oneline --graph --all --decorate";
        ds = "diff --staged";
        hk = "!lh() { find .git/hooks -mindepth 1 -maxdepth 1 | grep -v sample; }; lh";
      };

      attributes = [
        "flake.lock -diff"
        "Cargo.lock -diff"
      ];

      extraConfig = {
        init.defaultBranch = "main";

        push.autoSetupRemote = true;
        pull.ff = "only";
        fetch = {
          all = true;
          prune = true;
          pruneTags = true;
        };

        advice = {
          addEmptyPathspec = false;
          detachedHead = false;
        };

        difftool.prompt = false;
        mergetool.prompt = false;

        # todo.txt
        # TODO move todo.py to a package
        merge.todo.driver = "todo merge %A %O %B";
      };
    };
  };
}
