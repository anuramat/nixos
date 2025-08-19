# User configuration module - makes username and personal settings configurable
{ lib, config, ... }:
with lib;
let
  cfg = config.userConfig;
in
{
  options.userConfig = {
    # TODO defaults should be taken from home-manager git settings; if none -- throw an error
    username = mkOption {
      type = types.str;
      description = "Primary username for the system";
    };

    fullName = mkOption {
      type = types.str;
      description = "User's full name";
    };

    email = mkOption {
      type = types.str;
      description = "User's email address";
    };
  };

  config = {
    home-manager.users.${cfg.username} = {
      imports = [
        inputs.self.homeModules.${cfg.username}
      ];
    };
  };
}
