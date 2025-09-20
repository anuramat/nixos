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

    # office
    slides # markdown presentation in terminal
    # lookatme -- slides with images; not in nixpkgs yet
    tidy-viewer # csv viewer
    glow # markdown tui viewer
    poppler_utils # pdf utils
    pdftk # more pdf tools
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    easyocr # neural ocr
    pandoc # document converter
    quarto
    mystmd
    djvulibre # djvu tools
    markdown-link-check # find dead md links
    mermaid-cli

    # audio
    sox # cli audio processing
    lame # mp3

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
    tree-sitter
    ast-grep # structural regex

    # security
    age # file encryption
    ragenix # (r)agenix cli

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

    # visualization/graphics
    graphviz
    graph-easy
    gnuplot

    # system utilities
    asciinema
    pstree
    progress # progress status for cp etc
    pv # pipe viewer
    xdg-ninja # checks $HOME for junk

    # fun
    fastfetch
    banner
    figlet # fancy banners
    cowsay
    fortune # random quotes

    # miscellaneous unfiled TODO
    nix-search
    html2text # plain
    percollate # markdown
    gron # make json greppable
    csvkit
    firefox-sync-client
    remarshal
    # dix # not in stable yet
    nvd # nix diff
    nix-unit
    rename
    renameutils
    mitmproxy
    dotslash
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
    devenv # nix for retards

    # img
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format
    exiftool # read/write EXIF metadata
    chafa # sixel, kitty, iterm2, blocks; faster than timg atm (ll7, 2025-06-20)
    viu # kitty, iterm2, blocks, SOON sixel
    timg # sixel, kitty, iterm2, blocks

    # video
    ffmpeg-full

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
    nix-bash-completions
    p7zip
    tmux # just in case
    tree
    unrar-wrapper
    unzip
    wget
    zip

    # hardware
    libusb1 # user-mode USB access lib
    pciutils
    procps # info from /proc
    smartmontools # storage
    usbutils
  ];
}
