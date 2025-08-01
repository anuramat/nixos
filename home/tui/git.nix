{
  config,
  user,
  pkgs,
  ...
}:
let
  ghSettings = {
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
  difftastic = {
    enable = true;
    enableAsDifftool = true;
    display = "inline";
  };
  aliases = {
    wt = "worktree";
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
    lh = "!lh() { find .git/hooks -mindepth 1 -maxdepth 1 | grep -v sample; }; lh";
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
    "/.claude/settings.local.json"
    "/.crush"
    ".pytest_cache"

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
    # myst
    "_build"

    # direnv
    ".direnv/"
    ".envrc"
  ];
  attributes = [
    "*.ipynb diff=jupyternotebook merge=jupyternotebook"
    "flake.lock diff=nodiff"
  ];
  hooks = {
    pre-commit =
      config.lib.home.gitHook
        # bash
        ''
          hook_name=$(basename "$0")
          local=./.git/hooks/$hook_name
          [ -x "$local" ] && [ -f "$local" ] && {
            exec "$local"
          }

          if [ -f ./treefmt.toml ]; then
            treefmt --fail-on-change
          fi
        '';
  };
in
{
  programs = {
    gh = {
      enable = true;
      settings = ghSettings;
    };
    git = {
      enable = true;
      userEmail = user.email;
      userName = user.fullname;

      inherit
        attributes
        hooks
        ignores
        aliases
        difftastic
        ;

      # TODO check jupyter notebook and nbdime later; `git diff` works
      extraConfig = {
        fetch = {
          all = true;
          prune = true;
          pruneTags = true;
        };
        pull.ff = "only";
        core.pager = {
          diff =
            let
              # TODO make this work again...
              pattern = ''(?<! --- ([2-9]|\d{2,6})/\d{1,6}) --- \S+(?![/\d]* ---)'';
              # this is for lesskey:
              # escaped = lib.replaceStrings [ ''\'' ] [ ''\\'' ] pattern;
              # LESS = -ir +/${escaped}\ng
            in
            "less '+/${pattern}'$'\ng'";
        };
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
        # TODO I probably will never use this
        mergetool = {
          prompt = false;
          nbdime.cmd = "git-nbmergetool merge \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
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
      };
    };
  };
}
