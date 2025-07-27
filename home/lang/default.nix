{ pkgs, ... }:
{
  programs.go.enable = true;
  imports = [
    ./python.nix
    ./yaml.nix
  ];
  home.packages = with pkgs; [
    # compilers
    cabal-install
    cargo
    # clang # collision with gcc
    ghc
    gcc
    cudaPackages.cuda_nvcc
    julia
    llvm
    lua
    nodejs_20
    perl
    ruby
    rustc
    sageWithDoc # computer algebra system
    stack
    texliveFull
    yarn

    # linters
    deadnix # nix dead code
    golangci-lint # go
    luajitPackages.luacheck # lua
    shellcheck # *sh
    statix # nix
    yamllint

    # formatters
    black # python
    isort
    formatjson5
    gofumpt # stricter go
    haskellPackages.ormolu
    html-tidy
    (mdformat.withPlugins (p: [
      pkgs.mdformat-myst
      mdformat-deflist
      mdformat-wikilink
    ]))
    nixfmt-rfc-style
    cbfmt # mdformat ought to be enough?
    shfmt # posix/bash/mksh
    stylua # lua
    treefmt # aggregator
    yamlfmt

    # debuggers
    delve # Go debugger
    gdb # C
    python3Packages.debugpy

    # misc TODO categorize
    haskellPackages.hoogle
    htmlq
    jq # json processor
    jsonschema # `jv`
    nixtract # dependency graph of derivations
    pup # html
    python3Packages.jupytext
    python3Packages.nbdime # ipynb diff, merge
    yq # basic yaml, json, xml, csv, toml processor
  ];
}
