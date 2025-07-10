{
  programs = {

    swayimg = {
      enable = true;
      settings =
        let
          binds = {
            "Shift+Delete" = ''exec rmtrash '%' && echo "File removed: %"; skip_file'';
          };
        in
        {
          "keys.viewer" = binds;
          "keys.galllery" = binds;
        };
    };
    zathura = {
      enable = true;
      options = {
        adjust-open = "width";
        window-title-home-tilde = true;
        statusbar-basename = true;
        selection-clipboard = "clipboard";
        synctex = true;
        synctex-editor-command = "texlab inverse-search -i %{input} -l %{line}"; # result should be quoted I think
      };
    };

    mpv = {
      config = {
        profile = "gpu-hq";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        vo = "gpu";
        force-window = true;
        ytdl-format = "bestvideo+bestaudio";
        cache-default = 4000000;
      };
    };
  };
}
