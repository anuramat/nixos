args:
{
  imports = [
    ./sway
    ./clipboard.nix
    ./mako.nix
    ./menu.nix
    ./portals.nix
    ./swaylock.nix
  ];
}
// (
  if args ? osConfig then
    {
      services = {
        blueman-applet.enable = args.osConfig.services.blueman.enable;
        avizo = {
          enable = true;
          settings = {
            default = {
              time = 0.5;
            };
          };
        };
        udiskie = {
          enable = args.osConfig.services.udisks2.enable;
          notify = true;
          tray = "auto";
          automount = true;
        };
      };
      services.network-manager-applet.enable = args.osConfig.networking.networkmanager.enable;
    }
  else
    { }
)
