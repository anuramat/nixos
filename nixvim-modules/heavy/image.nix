{
  # snacks converts non-png images with imagemagick
  dependencies.imagemagick.enable = true;
  plugins = {
    img-clip.enable = true;
    # kitty protocol only; also used by fzf-lua previews; too slow over ssh
    snacks = {
      enable = true;
      settings.image.enabled.__raw = "vim.env.SSH_CONNECTION == nil";
    };
  };
}
