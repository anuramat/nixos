# Test the new user-config module
{ pkgs, lib }:
let
  inherit (lib) evalModules;
  
  # Helper to create a test configuration with user-config module
  mkTestConfigWithUserModule = userConfig: evalModules {
    modules = [
      # Base options
      ({ lib, ... }: {
        options = {
          userConfig = lib.mkOption { type = lib.types.anything; default = {}; };
          _module.args = lib.mkOption { type = lib.types.anything; default = {}; };
          time.timeZone = lib.mkOption { type = lib.types.str; default = ""; };
          home-manager.users = lib.mkOption { type = lib.types.anything; default = {}; };
        };
      })
      # Import the actual module
      (import ../../nixos-modules/user-config.nix)
      # User's configuration
      { userConfig = userConfig; }
    ];
    specialArgs = { inherit lib; };
  };
in
{
  # Test default values
  testUserConfigDefaults = {
    expr = let
      config = (mkTestConfigWithUserModule {}).config;
    in {
      username = config.userConfig.username;
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
      timezone = config.userConfig.timezone;
      notesPath = config.userConfig.personalPaths.notes;
    };
    expected = {
      username = "anuramat";
      fullName = "Arsen Nuramatov";
      email = "arsenovich@proton.me";
      timezone = "Europe/Berlin";
      notesPath = "/home/anuramat/notes";
    };
  };

  # Test custom username
  testUserConfigCustomUsername = {
    expr = let
      config = (mkTestConfigWithUserModule {
        username = "alice";
        fullName = "Alice Smith";
        email = "alice@example.com";
      }).config;
    in {
      username = config.userConfig.username;
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
      notesPath = config.userConfig.personalPaths.notes;
      booksPath = config.userConfig.personalPaths.books;
      todoPath = config.userConfig.personalPaths.todo;
    };
    expected = {
      username = "alice";
      fullName = "Alice Smith";
      email = "alice@example.com";
      notesPath = "/home/alice/notes";
      booksPath = "/home/alice/books";
      todoPath = "/home/alice/notes/todo.txt";
    };
  };

  # Test timezone configuration
  testUserConfigTimezone = {
    expr = let
      config = (mkTestConfigWithUserModule {
        timezone = "America/New_York";
      }).config;
    in {
      userTimezone = config.userConfig.timezone;
      systemTimezone = config.time.timeZone;
    };
    expected = {
      userTimezone = "America/New_York";
      systemTimezone = "America/New_York";
    };
  };

  # Test custom paths
  testUserConfigCustomPaths = {
    expr = let
      config = (mkTestConfigWithUserModule {
        username = "bob";
        personalPaths = {
          notes = "/data/bob/notes";
          books = "/media/library";
          todo = "/home/bob/.todo";
        };
      }).config;
    in {
      notesPath = config.userConfig.personalPaths.notes;
      booksPath = config.userConfig.personalPaths.books;
      todoPath = config.userConfig.personalPaths.todo;
    };
    expected = {
      notesPath = "/data/bob/notes";
      booksPath = "/media/library";
      todoPath = "/home/bob/.todo";
    };
  };

  # Test username in _module.args
  testUserConfigModuleArgs = {
    expr = let
      config = (mkTestConfigWithUserModule {
        username = "testuser";
      }).config;
    in {
      moduleArgUsername = config._module.args.username or null;
    };
    expected = {
      moduleArgUsername = "testuser";
    };
  };

  # Test personal modules enable/disable
  testUserConfigPersonalModules = {
    expr = let
      configEnabled = (mkTestConfigWithUserModule {
        username = "user1";
        enablePersonalModules = true;
      }).config;
      configDisabled = (mkTestConfigWithUserModule {
        username = "user2";
        enablePersonalModules = false;
      }).config;
    in {
      enabledOption = configEnabled.userConfig.enablePersonalModules;
      disabledOption = configDisabled.userConfig.enablePersonalModules;
    };
    expected = {
      enabledOption = true;
      disabledOption = false;
    };
  };
}