{ config, pkgs, ... }:
{
  programs.go = {
    enable = true;
    goPath = "${config.xdg.cacheHome}/go"; # ~/.cache/go
  };
  imports = [
    ./nix.nix
    ./python.nix
    ./yaml.nix
  ];
  home.packages = with pkgs; [
    # compilers
    cabal-install
    # cargo
    # rustc
    # clang # collision with gcc
    ghc
    gcc
    cudaPackages.cuda_nvcc
    julia
    llvm
    lua
    nodejs_20
    bun
    perl
    ruby
    sageWithDoc # computer algebra system
    stack
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
      p.mdformat-myst
    ]))
    nixfmt-rfc-style
    cbfmt # mdformat ought to be enough?
    shfmt # posix/bash/mksh
    shellharden # nazi quotes
    stylua # lua
    treefmt # aggregator
    yamlfmt

    # debuggers
    delve # Go debugger
    gdb # C
    python3Packages.debugpy

    # misc TODO categorize
    rustlings
    haskellPackages.hoogle
    htmlq
    jq # json processor
    jsonschema # `jv`
    nixtract # dependency graph of derivations
    pup # html
    python3Packages.jupytext
    yq-go # basic yaml, json, xml, csv, toml processor
    quicktype # json to types
  ];
}
