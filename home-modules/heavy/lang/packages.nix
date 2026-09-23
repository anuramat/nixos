{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # compilers
    cabal-install
    # cargo
    # rustc
    # clang # collision with gcc
    ghc
    julia
    llvm
    lua
    nodejs_26
    bun
    perl
    ruby
    # sage # computer algebra system; takes a while to build
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
    cbfmt # mdformat ought to be enough?
    shellharden # nazi quotes
    treefmt # aggregator

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
