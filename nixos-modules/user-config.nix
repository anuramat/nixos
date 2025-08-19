# User configuration module - makes username and personal settings configurable
{ lib, config, ... }:
with lib;
let
  cfg = config.userConfig;
in
{
  options.userConfig = {
    username = mkOption {
      type = types.str;
      default = "anuramat";  # Default for backward compatibility
      description = "Primary username for the system";
    };

    fullName = mkOption {
      type = types.str;
      default = "Arsen Nuramatov";  # Default for backward compatibility
      description = "User's full name";
    };

    email = mkOption {
      type = types.str;
      default = "arsenovich@proton.me";  # Default for backward compatibility
      description = "User's email address";
    };

    personalPaths = {
      notes = mkOption {
        type = types.path;
        default = "/home/${cfg.username}/notes";
        description = "Path to notes directory";
      };

      books = mkOption {
        type = types.path;
        default = "/home/${cfg.username}/books";
        description = "Path to books directory";
      };

      todo = mkOption {
        type = types.path;
        default = "/home/${cfg.username}/notes/todo.txt";
        description = "Path to todo file";
      };
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/Berlin";
      description = "User's timezone";
    };

    enablePersonalModules = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable personal configuration modules";
    };
  };

  config = {
    # Make username available in specialArgs for other modules
    _module.args.username = cfg.username;
    
    # Set timezone based on user config
    time.timeZone = cfg.timezone;

    # Conditionally import personal modules if enabled
    home-manager.users.${cfg.username} = mkIf cfg.enablePersonalModules {
      imports = lib.optional 
        (builtins.pathExists ../home-modules/${cfg.username}.nix)
        ../home-modules/${cfg.username}.nix;
    };
  };
}