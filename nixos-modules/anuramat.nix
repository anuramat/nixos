{ username, inputs, ... }:
{
  time.timeZone = "Europe/Berlin";

  home-manager.users.${username}.imports = [
    inputs.self.homeModules.anuramat
  ];
}
