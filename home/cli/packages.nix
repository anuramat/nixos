{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # tops
    ctop # containers
    gotop # cute
    iotop # detailed io info, requires sudo
    nvitop # nvidia gpu
    podman-tui # podman container status
    nvtopPackages.full # top for GPUs # maybe switch to .nvidia and .intel
    zenith-nvidia # top WITH nvidia GPUs

    # docs
    # TODO euporie (tui jupyter notebooks)
    slides # markdown presentation in terminal
    glow # markdown viewer
    poppler_utils # pdf utils
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    easyocr # neural OCR
    pandoc # markup converter (latex, markdown, etc)
    djvulibre # djvu tools

    # audio
    sox # CLI audio processing
    lame # mp3
    piper-tts # good neural TTS

    # ai / llm
    goose-cli
    tgpt
    aider-chat-full
    claude-code
    llama-cpp
    codex
    amp-cli

    # backend
    dive # look into docker image layers
    grpcui
    grpcurl
    httpie # curl++
    kubectl
    kubectx
    podman-compose

    # img
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format
    exiftool # read/write EXIF metadata
    chafa # sixel, kitty, iterm2, unicode
    timg # sixel, kitty, iterm2, unicode; faster than chafa

    # video
    ffmpeg-full
    yt-dlp # download youtube videos

    # file managers
    felix-fm # smallest, image previews -- :help<cr> for help; waiting for picker: <https://github.com/kyoheiu/felix/issues/261>
    nnn # small, simple, ubiquitous -- ? for help

    # data
    man-pages
    man-pages-posix
    manix # nix doc search with caching
    nix-index # search for files in in derivations
    cht-sh

    # sys
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
    p7zip
    tmux # just in case
    tree
    unrar-wrapper
    unzip
    util-linux # TODO check; I think it's already installed
    wget
    zip

    # misc TODO categorize
    bats # bash testing
    bear # compilation database generator for clangd
    haskellPackages.hoogle
    htmlq
    gomodifytags
    jq # json processor
    jsonschema # `jv`
    luajitPackages.luarocks
    markdown-link-check
    pup # html
    python3Packages.nbdime # ipynb diff, merge
    python3Packages.jupytext
    tidy-viewer # csv viewer
    universal-ctags # maintained ctags
    yq # basic yaml, json, xml, csv, toml processor
    geteduroam-cli
    ansifilter
    asciinema
    bubblewrap
    ansifilter
    pstree
    age # file encryption
    wine
    aria # downloader
    banner
    croc # send/receive files through relay with encryption TODO test if it needs setup
    makefile2graph
    mermaid-cli
    ddgr # ddg search
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
    python3Packages.pyicloud
    qrcp # send files to mobile over Wi-Fi using QR
    rclone # rsync for cloud
    tree-sitter
    cowsay
    fortune # random quotes

    # network
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

    # core
    subcat
    du-dust # du++
    duf # df++
    entr # file watcher - runs command on change
    ghq # git repository manager
    libqalculate # `qalc` - advanced calculator
    ncdu # du++: interactive
    rmtrash # `rmtrash`
    trashy # `trash`
    devenv # nix for retards
    eza # ls++
    watchman # another file watcher TODO try and compare to entr
    wayidle # runs a command on idle (one-off, orthogonal to swayidle)
    expect # automating tuis

    # hardware
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

    # python libraries for random scripts
    (python3.withPackages (
      p: with p; [
        mcp
      ]
    ))
  ];
}
