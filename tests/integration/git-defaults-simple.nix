# Tests for simplified git defaults in user-config module
{ pkgs, lib }:
let
  inherit (lib) evalModules;
  
  # Helper to create a test configuration with user-config and home-manager
  mkTestConfig = { userConfig ? {}, homeManager ? {}, expectError ? false }: 
    let 
      result = lib.tryEval (evalModules {
        modules = [
          # Base options
          ({ lib, ... }: {
            options = {
              userConfig = lib.mkOption { type = lib.types.anything; default = {}; };
              home-manager.users = lib.mkOption { type = lib.types.anything; default = {}; };
            };
          })
          # Mock inputs
          ({ lib, ... }: {
            _module.args.inputs = {
              self.homeModules.testuser = {
                programs.git = homeManager;
              };
            };
          })
          # Import the actual module
          (import ../../nixos-modules/user-config.nix)
          # User's configuration
          { 
            userConfig = userConfig // { username = "testuser"; };
          }
        ];
        specialArgs = { inherit lib; };
      });
    in
    if expectError then
      { success = result.success; error = !result.success; }
    else
      result.value;

in
{
  # Test 1: Only userConfig defined (should work)
  testOnlyUserConfig = {
    expr = let
      config = (mkTestConfig {
        userConfig = {
          fullName = "John Doe";
          email = "john@example.com";
        };
      }).config;
    in {
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
    };
    expected = {
      fullName = "John Doe";
      email = "john@example.com";
    };
  };

  # Test 2: Only git settings defined (should use as defaults)
  testOnlyGitSettings = {
    expr = let
      config = (mkTestConfig {
        homeManager = {
          userName = "Jane Smith";
          userEmail = "jane@example.com";
        };
      }).config;
    in {
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
    };
    expected = {
      fullName = "Jane Smith";
      email = "jane@example.com";
    };
  };

  # Test 3: Both defined (userConfig should override git)
  testBothDefined = {
    expr = let
      config = (mkTestConfig {
        userConfig = {
          fullName = "John Doe Override";
          email = "john.override@example.com";
        };
        homeManager = {
          userName = "Jane Smith";
          userEmail = "jane@example.com";
        };
      }).config;
    in {
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
    };
    expected = {
      fullName = "John Doe Override";
      email = "john.override@example.com";
    };
  };

  # Test 4: Neither defined (should throw error)
  testNeitherDefined = {
    expr = let
      result = mkTestConfig {
        userConfig = {};
        homeManager = {};
        expectError = true;
      };
    in {
      hasError = result.error;
    };
    expected = {
      hasError = true;
    };
  };

  # Test 5: Mixed scenario (fullName from userConfig, email from git)
  testMixedValues = {
    expr = let
      config = (mkTestConfig {
        userConfig = {
          fullName = "John Doe";
          # email will come from git
        };
        homeManager = {
          # userName not used since userConfig.fullName is set
          userName = "Jane Smith";
          userEmail = "jane@git.com";
        };
      }).config;
    in {
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
    };
    expected = {
      fullName = "John Doe";
      email = "jane@git.com";
    };
  };

  # Test 6: Git settings can coexist with userConfig (no conflicts)
  testNoConflicts = {
    expr = let
      config = (mkTestConfig {
        userConfig = {
          fullName = "Explicit Name";
          email = "explicit@email.com";
        };
        homeManager = {
          userName = "Git Name";
          userEmail = "git@email.com";
          # These can coexist - git just provides defaults
        };
      }).config;
    in {
      # userConfig values should be used (override defaults)
      fullName = config.userConfig.fullName;
      email = config.userConfig.email;
      # Git settings still exist for other purposes
      gitUserName = config.home-manager.users.testuser.programs.git.userName;
      gitUserEmail = config.home-manager.users.testuser.programs.git.userEmail;
    };
    expected = {
      fullName = "Explicit Name";
      email = "explicit@email.com";
      gitUserName = "Git Name";
      gitUserEmail = "git@email.com";
    };
  };
}