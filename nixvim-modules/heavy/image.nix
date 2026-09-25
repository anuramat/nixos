{
  # snacks converts non-png images with imagemagick
  dependencies.imagemagick.enable = true;
  plugins = {
    img-clip.enable = true;
    # kitty protocol only; also used by fzf-lua previews
    snacks = {
      enable = true;
      settings.image.enabled = true;
    };
  };
}
