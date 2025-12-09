{
  config,
  ...
}:
{
  imports = [
    ./difft.nix
    ./gh.nix
    ./ignores.nix
    ./jupyter.nix
    ./lazygit.nix
    ./worktrees.nix
  ];

  home.sessionVariables.GHQ_ROOT = "${config.xdg.dataHome}/ghq";
  programs = {

    git = {
      enable = true;

      attributes = [
        "flake.lock -diff"
        "Cargo.lock -diff"
      ];

      settings = {
        alias = {
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
