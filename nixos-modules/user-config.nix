# User configuration module - makes username and personal settings configurable
{
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  cfg = config.userConfig;
  inherit (cfg) username;
  homeConfig = config.home-manager.users.${username};
in
{
  options.userConfig = {
    username = mkOption {
      type = types.str;
      description = "primary username for the system";
    };

    # TODO: rename fullName to name?

    fullName = mkOption {
      type = types.str;
      default = homeConfig.programs.git.settings.user.name or (throw "no name provided");
    };

    email = mkOption {
      type = types.str;
      default = homeConfig.programs.git.settings.user.email or (throw "no email provided");
    };
  };

  config = {
    home-manager.users.${username} = {
      imports = [
        inputs.self.homeModules.${username}
      ];
    };
  };
}
