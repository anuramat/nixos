{
  programs = {
    swaylock = {
      # TODO HUH needs pam; it's already configured by programs.sway on nixos
      enable = true;
      settings =
        {
          ignore-empty-password = true;
          indicator-caps-lock = true;
        }
    };
  };
}
