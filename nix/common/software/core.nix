{
  pkgs,
  unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # docs {{{1
    man-pages
    man-pages-posix

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
    nvi # vi clone
    tmux # just in case
    tree
    unrar-wrapper
    unzip
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
    v4l-utils

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
    unstable.neovim
    # inputs.neovim-nightly-overlay.packages.${pkgs.system}.default
    unstable.helix
    unstable.vis

    # core {{{1
    inputs.subcat.packages.${pkgs.system}.default
    bat # cat++: syntax hl
    delta # pretty diff
    difftastic # diff++: syntax aware using TS
    du-dust # du++
    duf # df++
    entr # file watcher - runs command on change
    fd # find++
    gh # GitHub CLI
    ghq # git repository manager
    libqalculate # `qalc` - advanced calculator
    ncdu # du++: interactive
    parallel # run parallel jobs
    ripgrep # grep++
    ripgrep-all # ripgrep over docs, archives, etc
    rmtrash # rm but to trash
    tealdeer # tldr reimplementation: rust + xdg
    tgpt
    unstable.devenv
    unstable.eza # ls++
    (unstable.todo-txt-cli.overrideAttrs {
      # fixes <https://github.com/NixOS/nixpkgs/issues/367635>
      installPhase = ''
        install -vd $out/bin
        install -vm 755 todo.sh $out/bin
        install -vd $out/share/bash-completion/completions
        install -vm 644 todo_completion $out/share/bash-completion/completions/todo.sh
        install -vd $out/etc/todo
        install -vm 644 todo.cfg $out/etc/todo/config
      '';
    })
    watchman # another file watcher TODO try and compare to entr
    wayidle # runs a command on idle
    zellij # tmux++
    zoxide # cd++
    expect # automating tuis

    # misc {{{1
    asciinema
    ansifilter
    pstree
    age # file encryption
    virtualbox
    wine

    yazi # big
    felix-fm # smallest, image previews, waiting for picker: <https://github.com/kyoheiu/felix/issues/261>
    nnn # small, simple, ubiquitous
    xplr # small, hackable/lua, plugins, hard -- no time for this shit

    aria # downloader
    banner
    unstable.croc # send/receive files through relay with encryption
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
    rsbkb # rust blackbag - encode/decode tools: crc
    scc # sloc cloc and code: dick measuring tool
    speedtest-cli
    unstable.xdg-ninja # checks $HOME for junk
    git-filter-repo # rewrite/analyze repository history
    mosh # ssh over unstable connections
    python311Packages.pyicloud
    qrcp # send files to mobile over Wi-Fi using QR
    rclone # rsync for cloud
    tree-sitter
    mesa-demos # some 3d demos, useful for graphics debugging
    cowsay
    fortune # random quotes

    # backend {{{1
    dbeaver-bin # databases
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
    unstable.nvtopPackages.full # top for GPUs (doesn't support intel yet)
    zenith-nvidia # top WITH nvidia GPUs

    # img {{{1
    krita # raster graphics, digital art
    inkscape-with-extensions # vector graphics
    gimp-with-plugins # raster graphics
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format
    exiftool # read/write EXIF metadata
    # mypaint # not-ms-paint # XXX broken
    nomacs # image viewer # TODO remove?
    xfig # vector graphics, old as FUCK
    swayimg # image viewer
    chafa # sixel, kitty, iterm2, unicode
    timg # sixel, kitty, iterm2, unicode
    ueberzugpp # terminal images + native overlay
    unstable.lsix # sixel ls

    # video {{{1
    vlc
    mpv
    # davinci-resolve
    handbrake
    unstable.footage
    ffmpeg
    yt-dlp # download youtube videos

    # audio {{{1
    sox # CLI audio processing
    lame # mp3
    alsa-utils
    piper-tts # good neural TTS

    # docs {{{1
    slides # markdown presentation in terminal
    glow # markdown viewer
    poppler_utils # pdf utils
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    okular # reader # TODO remove?
    djview # djvu reader # TODO remove?
    unstable.zathura # keyboard-centric aio reader
    zotero # TODO do I need this?
    easyocr # neural OCR
    pandoc # markup converter (latex, markdown, etc)
    djvulibre # djvu tools
    xournalpp # pdf markup, handwritten notes
    # }}}
  ];
}
# vim: fdm=marker fdl=0
