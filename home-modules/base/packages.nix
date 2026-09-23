{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # absolute minimum
    bc # simple calculator
    coreutils-full
    curl
    file
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
    nvtopPackages.full # top for GPUs

    # processes
    procps # info from /proc
    progress # progress status for cp etc
    pstree # ps tree :)
    pv # pipe viewer

    # files
    rename
    renameutils

    # data
    fx # json viewer
    gron # make json greppable (every value gets its own line)
    remarshal # convert between json, toml, yaml, ...
    csvkit
    html2text # html to plain text
    tidy-viewer # csv viewer

    # development
    ansifilter # filter out scary chars
    dotslash
    entr # file watcher - runs command on change
    expect # automating tuis
    hyperfine # CLI benchmarking, a-la `time`
    mprocs # job runner
    rsbkb # rust blackbag - encode/decode tools
    scc # sloc cloc and code: dick measuring tool
    universal-ctags # maintained ctags

    # nix
    cachix
    nix-auth

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
    gum # shell library
    nix-bash-completions
    wishlist # ssh menu
  ];
}
