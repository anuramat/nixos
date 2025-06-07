{
  pkgs,
  old,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # compilers {{{1
    cabal-install
    cargo
    clang
    ghc
    gcc
    cudaPackages.cuda_nvcc
    go
    julia
    llvm
    lua
    nodejs_20
    perl
    python3
    ruby
    rustc
    old.sageWithDoc # computer algebra system
    stack
    texliveFull
    yarn

    # debuggers {{{1
    delve # Go debugger
    gdb # C
    python311Packages.debugpy

    # formatters {{{1
    black # python
    formatjson5
    gofumpt # stricter go
    haskellPackages.ormolu
    html-tidy
    markdownlint-cli # also, remark sounds promising
    nixfmt-rfc-style
    nodePackages.prettier # just in case
    shfmt # posix/bash/mksh
    stylua # lua
    treefmt # aggregator
    yamlfmt

    # mcp {{{1
    github-mcp-server
    mcp-nixos

    # misc {{{1
    bats # bash testing
    bear # compilation database generator for clangd
    haskellPackages.hoogle
    htmlq
    gomodifytags
    jq # json processor
    luajitPackages.luarocks
    markdown-link-check
    pup # html
    old.python311Packages.nbdime # ipynb diff, merge
    python3Packages.jupytext
    tidy-viewer # csv viewer
    universal-ctags # maintained ctags
    yq # basic yaml, json, xml, csv, toml processor
    # mathematica requires the .sh installer to be in the nix store
    # `nix-store --add-fixed sha256 Mathematica_14.0.0_BNDL_LINUX.sh`
    # TODO move to notes
    # mathematica
    # }}}
  ];
}
# vim: fdm=marker fdl=0
