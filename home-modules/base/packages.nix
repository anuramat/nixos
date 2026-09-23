{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # absolute minimum
    bc # simple calculator
    coreutils-full
    curl
    file
    gcc
    git
    gnumake
    less
    lsof
    moreutils # random unixy goodies
    python3
    tmux # just in case
    tree
    wget
    xxd

    # archives
    p7zip
    unrar-wrapper
    unzip
    zip

    # modern replacements
    duf # df++
    dust # du++
    eza # ls++
    ncdu # du++: interactive

    # tops
    bottom
    gotop

    # processes
    progress # progress status for cp etc
    pstree # ps tree :)
    pv # pipe viewer

    # hardware
    pciutils
    procps # info from /proc
    smartmontools # storage
    usbutils

    # files
    rename
    renameutils

    # data
    fx # json viewer
    gron # make json greppable (every value gets its own line)
    remarshal # convert between json, toml, yaml, ...

    # network
    aria2 # downloader
    croc # send/receive files through relay with encryption
    dig # dns utils
    gsocket # get shit through nat
    httpie # curl++
    inetutils # common network stuff
    mosh # ssh over unstable connections
    mtr # net diagnostics
    netcat
    prettyping # ping++
    rclone # rsync for cloud
    socat # socket cat
    speedtest-cli
    sshfs

    # security
    age # file encryption
    ragenix # (r)agenix cli

    # manuals
    cht-sh
    man-pages
    man-pages-posix

    # shell
    nix-bash-completions
  ];
}
