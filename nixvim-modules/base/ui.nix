{
  plugins = {
    # diffview pulls this in anyway; nixvim deprecated the implicit enable
    web-devicons.enable = true;

    fidget.enable = true;
    nvim-lightbulb = {
      enable = true;
      settings.virtual_text.enabled = true;
    };

    rainbow-delimiters.enable = true;

    colorizer = {
      enable = true;
      settings = {
        user_default_options = {
          css = true;
          yaml = true;
        };
      };
    };
  };
}
