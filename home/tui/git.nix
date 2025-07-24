{
  config,
  hax,
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
          push = "repo create --disable-issues --disable-wiki --public --source=.";
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

        # direnv
        ".direnv/"
        ".envrc"
      ];
      attributes = [
        "*.ipynb diff=jupyternotebook merge=jupyternotebook"
        "flake.lock diff=nodiff"
      ];

      hooks = {
        prepare-commit-msg =
          hax.common.gitHook pkgs
            # bash
            ''
              COMMIT_MSG_FILE=$1
              COMMIT_SOURCE=$2

              # NOTE that COMMIT_MSG_FILE only has comments when it's invoked interactively
              # meanwhile with `commit -m` it already contains the message
              # e.g. claude always uses `commit -m`
              signature="Co-Authored-By: ${config.lib.agents.varNames.agentName}"
              if [ -v ${config.lib.agents.varNames.agentName} ]; then
              	if [ "$COMMIT_SOURCE" = "commit" ]; then
              		echo 'permission error: agents are not allowed to use `git commit` with flags `-c`, `-C`, or `--amend`'
              		exit 1
              	fi
              	if ! [ -s "$COMMIT_MSG_FILE" ]; then
              		echo 'error: empty commit message'
              		exit 1
              	fi
              	if grep -q "$signature" "$COMMIT_MSG_FILE"; then
              		echo 'assertion error: commit already contains a "Co-Authored-By" trailer'
              		exit 1
              	fi
              	printf '\n%s' "$signature" >> "$COMMIT_MSG_FILE"
              fi
            '';
        pre-commit =
          hax.common.gitHook pkgs
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
