{
  pkgs,
  unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Compilers {{{1
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
    sageWithDoc # computer algebra system
    stack
    texliveFull
    yarn

    # Debuggers {{{1
    delve # Go debugger
    gdb # C
    python311Packages.debugpy

    # Formatters {{{1
    black # python
    cbfmt # md code blocks
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

    # Servers {{{1
    (haskell-language-server.override {
      supportedGhcVersions = [
        "927"
        "966"
      ];
    })
    bash-language-server
    ccls
    clang-tools
    gopls
    lua-language-server
    marksman
    nil
    nodePackages_latest.vscode-json-languageserver
    pyright
    texlab
    unstable.nixd
    yaml-language-server

    # Linters {{{1
    checkmake # makefile
    deadnix # nix dead code
    golangci-lint # go
    luajitPackages.luacheck # lua
    shellcheck # *sh
    statix # nix
    yamllint

    # Misc {{{1
    bats # bash testing
    bear # compilation database generator for clangd
    haskellPackages.hoogle
    htmlq
    jq # json processor
    luajitPackages.luarocks
    markdown-link-check
    pup # html
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
