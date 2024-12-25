{
  pkgs,
  unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Compilers {{{1
    cargo
    clang
    go
    julia
    llvm
    lua
    nodejs_20
    perl
    python3
    ruby
    rustc
    texliveFull
    unstable.cabal-install
    unstable.ghc
    unstable.stack
    yarn

    # Debuggers {{{1
    delve # Go debugger
    gdb # C
    python311Packages.debugpy

    # Formatters {{{1
    alejandra # nix
    black # Python
    cbfmt # code block formatter for markdown
    formatjson5
    gofumpt # strict(er) go
    html-tidy
    markdownlint-cli
    nixfmt-rfc-style # nix (OFFICIAL)
    nodePackages.prettier # formatting
    shfmt # posix/bash/mksh
    stylua # Lua
    treefmt
    yamlfmt # YAML

    # Servers {{{1
    nodePackages_latest.bash-language-server
    nodePackages_latest.yaml-language-server
    nodePackages_latest.vscode-json-languageserver
    lua-language-server
    texlab
    unstable.haskell-language-server
    unstable.nixd
    ccls
    nil
    pyright
    gopls
    marksman
    clang-tools

    # Linters {{{1
    luajitPackages.luacheck # lua
    golangci-lint # go
    deadnix # nix dead code
    statix # nix
    shellcheck # *sh
    checkmake # makefile

    # Misc {{{1
    jq # json processor
    yq # basic yaml, json, xml, csv, toml processor
    htmlq
    tidy-viewer # csv viewer
    pup # html
    bats # Bash testing
    universal-ctags # maintained ctags
    bear # Compilation database generator for clangd
    luajitPackages.luarocks
    haskellPackages.hoogle
    sageWithDoc # computer algebra system
    # mathematica requires the .sh installer to be in the nix store
    # `nix-store --add-fixed sha256 Mathematica_14.0.0_BNDL_LINUX.sh`
    # will probably need to get commented out on the first install
    # TODO maybe make optional later somehow? through a separate flake probably
    # mathematica
    # }}}
  ];
}
# vim: fdm=marker fdl=0
