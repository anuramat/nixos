{
  config,
  lib,
  pkgs,
  ...
}:
let
  file_separator_string = "<filesep>";
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
    ".crush/"
    ".pytest_cache"
    ".goose/"

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
    "flake.lock -diff"
  ];
  hooks = {
    pre-commit =
      config.lib.home.gitHook
        # bash
        ''
          hook_name=$(basename "$0")
          local=./.git/hooks/$hook_name
          [ -x "$local" ] && {
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

      inherit
        attributes
        hooks
        ignores
        aliases
        ;

      difftastic = {
        enable = true;
        package =
          let
            wrapped = pkgs.writeShellApplication {
              name = pkgs.difftastic.meta.mainProgram;
              runtimeInputs = with pkgs; [
                difftastic
                gawk
                git
              ];
              text = ''
                echo '${file_separator_string}'
                if (($# >= 7)); then
                  path="''${*: -7:1}"
                  old="''${*: -6:1}"
                  new="''${*: -3:1}"
                  if [[ -r $old ]] && [[ -r $new ]]; then
                    state=$(git check-attr diff -- "$path" | awk '{print $3}')
                    if [[ $state == "unset" ]]; then # corresponds to `pattern -diff` in `.gitattributes`
                      echo "skipping $path"
                      exit 0
                    fi
                  fi
                fi
                exec difft "$@"
              '';
              excludeShellChecks = map (v: "SC" + toString v) config.lib.excludeShellChecks.numbers;
            };
          in
          wrapped;
        enableAsDifftool = false;
        display = "inline";
      };

      # TODO check jupyter notebook and nbdime later; `git diff` works
      extraConfig = {
        fetch = {
          all = true;
          prune = true;
          pruneTags = true;
        };
        pull.ff = "only";
        core.pager =
          let
            less-with-search =
              let
                wrapped = pkgs.writeShellScriptBin "less-difft" ''
                  exec less -rp '${file_separator_string}' "$@"
                '';
              in
              lib.getExe wrapped;
          in
          {
            diff = less-with-search;
            show = less-with-search;
            log = less-with-search;
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
