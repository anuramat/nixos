{ pkgs, ... }:
{
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
    go
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
    checkmake # makefile
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
    mdformat
    nixfmt-rfc-style
    nodePackages.prettier # just in case
    shfmt # posix/bash/mksh
    stylua # lua
    treefmt # aggregator
    yamlfmt

    # debuggers {{{1
    delve # Go debugger
    gdb # C
    python3Packages.debugpy
  ];
}
