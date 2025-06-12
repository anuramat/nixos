# vim: fdm=marker fdl=0
{
  pkgs,
  old,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # docs
    man-pages
    man-pages-posix
    manix # nix doc search with caching

    # minimal set of tools
    bc # simple calculator
    coreutils-full
    curl
    file
    gcc
    git
    gnumake
    killall
    less
    lsof
    moreutils # random unixy goodies
    nix-bash-completions
    old.nvi # vi clone
    tmux # just in case
    tree
    unrar-wrapper
    unzip
    p7zip
    util-linux # I think it's already installed but whatever
    wget
    zip
    bubblewrap
  ];
}
