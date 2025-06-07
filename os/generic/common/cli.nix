# vim: fdm=marker fdl=0
{
  pkgs,
  old,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # docs {{{1
    man-pages
    man-pages-posix
    manix # nix doc search

    # posix {{{1
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

    # hardware {{{1
    acpi # battery status etc
    dmidecode # read hw info from bios using smbios/dmi
    efibootmgr # EFI boot manager editor
    hwinfo
    libusb1 # user-mode USB access lib
    libva-utils # vainfo - info on va-api
    lshw # hw info
    pciutils
    procps # info from /proc
    smartmontools # storage
    nvme-cli
    smem # ram usage
    usbutils
    v4l-utils # camera stuff

    # network {{{1
    aircrack-ng
    mtr # net diagnostics
    dig # dns utils
    gsocket # get shit through nat
    inetutils # common network stuff
    netcat
    nmap
    socat # socket cat
    wirelesstools # iwconfig etc
    openconnect_openssl

    # editors {{{1
    vis

    # core {{{1
    inputs.subcat.packages.${pkgs.system}.default
    bat # cat++: syntax hl
    delta # pretty diff
    du-dust # du++
    duf # df++
    entr # file watcher - runs command on change
    fd # find++
    ghq # git repository manager
    libqalculate # `qalc` - advanced calculator
    ncdu # du++: interactive
    parallel # run parallel jobs
    ripgrep # grep++
    ripgrep-all # ripgrep over docs, archives, etc
    rmtrash # rm but to trash
    trashy
    tealdeer # tldr reimplementation: rust + xdg
    devenv
    eza # ls++
    watchman # another file watcher TODO try and compare to entr
    wayidle # runs a command on idle
    zellij # tmux++
    expect # automating tuis

    # ai {{{1
    tgpt
    aider-chat-full
    claude-code
    llama-cpp

    # misc {{{1
    asciinema
    ansifilter
    pstree
    age # file encryption
    wine
    aria # downloader
    banner
    croc # send/receive files through relay with encryption TODO might be broken, unstable worked tho
    makefile2graph
    mermaid-cli
    mermaid-filter
    graphviz
    graph-easy
    distrobox
    exercism # CLI for exercism.org
    fastfetch
    figlet # fancy banners
    gnuplot
    mprocs # job runner
    prettyping # ping++
    progress # progress status for cp etc
    pv # pipe viewer
    rsbkb # rust blackbag - encode/decode tools
    nixtract # dependency graph of derivations
    scc # sloc cloc and code: dick measuring tool
    speedtest-cli
    xdg-ninja # checks $HOME for junk
    git-filter-repo # rewrite/analyze repository history
    mosh # ssh over unstable connections
    python311Packages.pyicloud
    qrcp # send files to mobile over Wi-Fi using QR
    rclone # rsync for cloud
    tree-sitter
    cowsay
    fortune # random quotes
    # file managers
    yazi # big, simple, hackable/lua -- ~ for help
    felix-fm # smallest, image previews -- :help<cr> for help; waiting for picker: <https://github.com/kyoheiu/felix/issues/261>
    nnn # small, simple, ubiquitous -- ? for help

    # backend {{{1
    dive # look into docker image layers
    grpcui
    grpcurl
    httpie # curl++
    kubectl
    kubectx
    podman-compose

    # tops {{{1
    btop # best
    ctop # containers
    gotop # cute
    htop # basic
    iotop # detailed io info, requires sudo
    nvitop # nvidia gpu
    podman-tui # podman container status
    nvtopPackages.full # top for GPUs # maybe switch to .nvidia and .intel
    zenith-nvidia # top WITH nvidia GPUs

    # img {{{2
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format
    exiftool # read/write EXIF metadata
    chafa # sixel, kitty, iterm2, unicode
    timg # sixel, kitty, iterm2, unicode; faster than chafa

    # video {{{1
    ffmpeg-full
    yt-dlp # download youtube videos

    # audio {{{1
    sox # CLI audio processing
    lame # mp3
    piper-tts # good neural TTS

    # docs {{{1
    slides # markdown presentation in terminal
    glow # markdown viewer
    poppler_utils # pdf utils
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    easyocr # neural OCR
    pandoc # markup converter (latex, markdown, etc)
    djvulibre # djvu tools
    # }}}
  ];
}
