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
  username = cfg.username;
  homeConfig = config.home-manager.users.${username};
in
{
  options.userConfig = {
    username = mkOption {
      type = types.str;
      description = "Primary username for the system";
    };

    fullName = mkOption {
      type = types.str;
      default =
        homeConfig.programs.git.userName
          or (throw "No full name provided. Set either userConfig.fullName or programs.git.userName.");
      description = "User's full name (defaults to programs.git.userName)";
    };

    email = mkOption {
      type = types.str;
      default =
        homeConfig.programs.git.userEmail
          or (throw "No email provided. Set either userConfig.email or programs.git.userEmail.");
      description = "User's email address (defaults to programs.git.userEmail)";
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
