{
  config,
  user,
  pkgs,
  ...
}:
{
  programs = {
    gh = {
      enable = true;
      settings = {
        aliases = {
          login = "auth login --skip-ssh-key --hostname github.com --git-protocol ssh --web";
        };
        extensions = with pkgs; [
          gh-f
          gh-copilot
          # # wait until they appear
          # copilot-insights
          # token
        ];
        git_protocol = "ssh";
        prompt = true;
      };
    };
    git = {
      enable = true;
      difftastic = {
        enable = true;
        enableAsDifftool = true;
        display = "inline";
      };
      # TODO move hardcode to an option or something
      userEmail = user.email;
      userName = user.fullname;
      aliases = {
        st = "status";
        sh = "show --ext-diff";
        ch = "checkout";
        br = "branch";
        sw = "switch";
        cm = "commit";
        ps = "push";
        l = "log --ext-diff";
        lg = "log --ext-diff --oneline --graph --all --decorate";
        df = "diff";
        ds = "diff --staged";
      };
      ignores = [
        "*.db" # jupyter-lab, maybe etc
        ".DS_Store" # macOS
        ".cache/" # clangd, maybe etc
        ".devenv*"
        ".env"
        ".htpasswd"
        ".ipynb_checkpoints/"
        ".stack-work/" # haskell
        "__pycache__/"
        "node_modules/"
        "result" # nix
        "tags"
        "venv/"
        "/.aider*"
        "/.claude/settings.local.json"

        # pytorch lightning
        "*.ckpt"
        "lightning_logs"

        # go, maybe etc
        "cover.cov"
        "coverage.html"
        ".testCoverage.txt"

        # latex temp stuff
        "*.aux"
        "*.fdb_latexmk"
        "*.fls"
        "*.log"

        # direnv
        ".direnv/"
        ".envrc"
      ];
      attributes = [
        "*.ipynb diff=jupyternotebook merge=jupyternotebook"
      ];

      # TODO check jupyter notebook and nbdime later; `git diff` works
      extraConfig = {
        pull.ff = "only";
        core.pager = "less -F";
        init.defaultBranch = "main";
        advice = {
          addEmptyPathspec = false;
          detachedHead = false;
        };
        push.autoSetupRemote = true;

        ghq.root = "${config.xdg.dataHome}/ghq";

        merge = {
          todo.driver = "todo merge %A %O %B";
          jupyternotebook = {
            driver = "git-nbmergedriver merge %O %A %B %L %P";
            name = "jupyter notebook merge driver";
          };
        };

        diff = {
          nodiff.command = "__nodiff() { echo skipping \"$1\"; }; __nodiff";
          jupyternotebook.command = "git-nbdiffdriver diff";
        };

        difftool = {
          prompt = false;
          nbdime.cmd = "git-nbdifftool diff \"$LOCAL\" \"$REMOTE\" \"$BASE\"";
        };
        pager.difftool = true;

        # I probably will never use this
        mergetool = {
          prompt = false;
          nbdime.cmd = "git-nbmergetool merge \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
        };

      };
    };
  };
}
