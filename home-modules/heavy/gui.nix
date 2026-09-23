# cross-platform graphical apps
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # unfiled
    dbeaver-bin # databases
    qalculate-gtk # qalc calculator gui
    transmission_4-gtk # torrent client

    # documents
    gnumeric # spreadsheets
    pdfpc # pdf presentations, broken on wayland
    pympress # pdf presentations
    zotero

    # notes
    rnote
    xournalpp # pdf markup, handwritten notes

    # img
    darktable

    # video
    losslesscut-bin

    # audio
    audacity

    # comms
    discord
    element-desktop # matrix client
    telegram-desktop
    zoom-us

    # browsers
    google-chrome

    # terminals
    cool-retro-term
  ];
}
