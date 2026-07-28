{
  lib,
  inputs,
  config,
  ...
}:
let
  cfg = config.userConfig;
  inherit (cfg) username name;
  homeConfig = config.home-manager.users.${username};
in
{
  options = with lib; {
    userConfig = {
      username = mkOption {
        type = types.str;
        description = "primary username for the system";
      };

      name = mkOption {
        type = types.str;
        default = homeConfig.programs.git.settings.user.name or (throw "no name provided");
      };

      email = mkOption {
        type = types.str;
        default = homeConfig.programs.git.settings.user.email or (throw "no email provided");
      };
    };
  };
  config = {
    home-manager.users.${username} = {
      imports = [
        inputs.self.homeModules.${username}
      ];
    };

    services.openssh.settings.AllowUsers = [ username ];
    users.users = {
      ${username} = {
        description = name;
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # root
        openssh.authorizedKeys = {
          inherit (config.lib.hosts) keyFiles;
        };
      };
    };
  };
}
