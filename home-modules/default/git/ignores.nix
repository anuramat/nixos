{
  programs.git.ignores = [
    ".agentfs/"
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
    ".quarto/"
    "/target" # rust
    "**/*.rs.bk"

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
}
