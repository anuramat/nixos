{
  pkgs,
  old,
  ...
}:
{
  # TODO move as much as possible to home-manager (make sure not to break the system)
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
    (python3.withPackages (
      p: with p; [
        mcp
      ]
    ))
    ruby
    rustc
    sageWithDoc # computer algebra system
    stack
    texliveFull
    yarn

    # debuggers {{{1
    delve # Go debugger
    gdb # C
    python311Packages.debugpy

    # formatters {{{1
    black # python
    isort
    formatjson5
    gofumpt # stricter go
    haskellPackages.ormolu
    html-tidy
    mdformat
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
    jsonschema # `jv`
    luajitPackages.luarocks
    markdown-link-check
    pup # html
    python3Packages.nbdime # ipynb diff, merge
    python3Packages.jupytext
    tidy-viewer # csv viewer
    universal-ctags # maintained ctags
    yq # basic yaml, json, xml, csv, toml processor
  ];
}
# vim: fdm=marker fdl=0
