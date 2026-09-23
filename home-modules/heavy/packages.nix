{ pkgs, ... }:
{
  # TODO euporie (tui jupyter notebooks)
  home.packages = with pkgs; [
    # development
    ansifilter # filter out scary chars
    ast-grep # structural regex
    bats # bash testing
    bear # compilation database generator for clangd
    dotslash
    entr # file watcher - runs command on change
    expect # automating tuis
    gomodifytags
    hyperfine # CLI benchmarking, a-la `time`
    lspmux
    makefile2graph
    mprocs # job runner
    rsbkb # rust blackbag - encode/decode tools
    scc # sloc cloc and code: dick measuring tool
    sem
    universal-ctags # maintained ctags

    # hardware
    libusb1 # user-mode USB access lib
    nvtopPackages.full # top for GPUs

    # nix
    cachix
    nix-auth

    # network
    aircrack-ng
    ddgr # ddg search
    grpcui
    grpcurl
    mitmproxy
    nmap
    openconnect_openssl
    qrcp # share files over qr
    tshark

    # cloud/sync
    firefox-sync-client
    proton-drive-cli

    # data
    csvkit
    html2text # html to plain text
    tidy-viewer # csv viewer

    # terminal recording
    asciinema
    vhs # terminal gif generator

    # shell scripting
    gum # shell library
    wishlist # ssh menu

    # misc
    caut # codex/claude usage
    exercism # cli for exercism.org
    libqalculate # `qalc` - advanced calculator
    qrrs # generate/read QR codes
    xdg-ninja # checks $HOME for junk
    yt-dlp # download youtube videos

    # img
    exiftool # read/write EXIF metadata
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format

    # terminal image viewers
    chafa
    timg
    viu

    # video
    ffmpeg

    # audio
    lame # mp3
    sox # cli audio processing

    # documents
    djvulibre # djvu tools
    ghostscript # postscript/pdf utils
    glow # markdown tui viewer
    markdown-link-check # find dead md links
    mermaid-cli
    pandoc # document converter
    pdftk # more pdf tools
    poppler-utils # pdf utils
    readability-cli # extracts main content from pages
    slides # markdown presentation in terminal
    # lookatme -- slides with images; not in nixpkgs yet
    # texliveFull

    # visualization/graphics
    gnuplot
    graph-easy
    graphviz

    # fun
    banner
    cowsay
    fastfetch
    figlet # fancy banners
    fortune # random quotes
  ];
}
