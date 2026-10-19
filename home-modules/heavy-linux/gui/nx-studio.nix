{ pkgs, ... }:
{
  home.packages = [ pkgs.nx-studio ];

  programs.niri.settings.window-rules = [
    {
      matches = [
        {
          app-id = "^nxstudio\\.exe$";
          title = "^NX Studio";
        }
      ];
      open-maximized = true;
    }
  ];
}
