{ pkgs, ... }:
{
  # TODO euporie (tui jupyter notebooks)
  home.packages = with pkgs; [
    # tops
    bottom
    ctop # containers
    gotop
    podman-tui # podman container status
    nvtopPackages.full # top for GPUs

    # containers
    dive # look into docker image layers
    kubectl
    kubectx
    podman-compose

    # development
    bats # bash testing
    bear # compilation database generator for clangd
    gomodifytags
    universal-ctags # maintained ctags
    ast-grep # structural regex

    # security
    age # file encryption
    ragenix # (r)agenix cli
    cryptsetup # luks etc

    # network/communication
    aircrack-ng
    grpcui
    grpcurl
    httpie # curl++
    aria # downloader
    croc # send/receive files through relay with encryption
    ddgr # ddg search
    dig # dns utils
    gsocket # get shit through nat
    inetutils # common network stuff
    mosh # ssh over unstable connections
    mtr # net diagnostics
    netcat
    nmap
    openconnect_openssl
    prettyping # ping++
    qrcp # share files over qr
    rclone # rsync for cloud
    socat # socket cat
    speedtest-cli

    # system utilities
    pstree # ps tree :)
    progress # progress status for cp etc
    pv # pipe viewer

    # fun
    fastfetch
    banner
    figlet # fancy banners
    cowsay
    fortune # random quotes

    # miscellaneous unfiled TODO
    html2text # html to plain text
    percollate # html to markdown
    fx # json viewer
    gron # make json greppable (every value gets its own line)
    csvkit
    firefox-sync-client
    remarshal # convert between json, toml, yaml, ...
    nix-bash-completions
    rename
    renameutils
    mitmproxy
    dotslash
    xdg-ninja # checks $HOME for junk
    asciinema
    hyperfine # CLI benchmarking, a-la `time`
    python3
    just
    wishlist # ssh menu
    vhs # terminal gif generator
    gum # shell library
    exercism # cli for exercism.org
    libqalculate # `qalc` - advanced calculator
    yt-dlp # download youtube videos

    # dev
    ansifilter # filter out scary chars
    makefile2graph
    mprocs # job runner
    rsbkb # rust blackbag - encode/decode tools
    scc # sloc cloc and code: dick measuring tool
    git-filter-repo # rewrite/analyze repository history
    entr # file watcher - runs command on change
    ghq # git repository manager
    expect # automating tuis

    # file managers
    felix-fm # smallest, image previews -- :help<cr> for help; waiting for picker: <https://github.com/kyoheiu/felix/issues/261>
    nnn # small, simple, ubiquitous -- ? for help

    # manuals
    man-pages
    man-pages-posix
    cht-sh

    # modern replacements
    du-dust # du++
    duf # df++
    ncdu # du++: interactive
    eza # ls++

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
    p7zip
    tmux # just in case
    tree
    unrar-wrapper
    unzip
    wget
    zip
    btrfs-progs
  ];
}
