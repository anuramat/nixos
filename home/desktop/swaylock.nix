let
  useRed = false;
in
{
  programs = {
    swaylock = {
      # needs pam; it's already configured by programs.sway on nixos
      enable = true;
      settings =
        {
          ignore-empty-password = true;
          indicator-caps-lock = true;

          # red
        }
        // (
          if useRed then
            {
              color = "ff0000";

              inside-color = "ff0000";
              line-color = "000000";
              ring-color = "ff0000";

              inside-clear-color = "ff0000";
              line-clear-color = "ff0000";
              ring-clear-color = "ff0000";

              inside-wrong-color = "ff0000";
              line-wrong-color = "000000";
              ring-wrong-color = "ff0000";

              inside-ver-color = "ff0000";
              line-ver-color = "ff0000";
              ring-ver-color = "ff0000";

              layout-bg-color = "00000000";
              layout-border-color = "00000000";
              layout-text-color = "000000";

              key-hl-color = "000000";

              # remove the text
              text-caps-lock-color = "00000000";
              text-clear-color = "00000000";
              text-color = "00000000";
              text-ver-color = "00000000";
              text-wrong-color = "00000000";
            }
          else
            { }
        );
    };
  };
}
