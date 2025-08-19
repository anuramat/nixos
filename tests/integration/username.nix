# Integration tests for username configuration
{ pkgs, lib }:
let
  inherit (lib) evalModules;
  
  # Helper to create a test configuration with a specific username
  mkTestConfig = username: evalModules {
    modules = [
      # Base module with minimal NixOS config
      ({ lib, ... }: {
        options = {
          users.users = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
          };
          services.getty.autologinUser = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          home-manager.users = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
          };
        };
      })
      # Import our mock module
      (import ./mock-nixos-module.nix)
    ];
    specialArgs = { inherit username lib; };
  };
in
{
  # Test default username (current hardcoded value)
  testDefaultUsername = {
    expr = let
      config = (mkTestConfig "anuramat").config;
    in {
      userExists = config.users.users ? anuramat;
      isNormalUser = config.users.users.anuramat.isNormalUser or false;
      autologinUser = config.services.getty.autologinUser;
      homeManagerConfigured = config.home-manager.users ? anuramat;
    };
    expected = {
      userExists = true;
      isNormalUser = true;
      autologinUser = "anuramat";
      homeManagerConfigured = true;
    };
  };

  # Test custom username
  testCustomUsername = {
    expr = let
      config = (mkTestConfig "alice").config;
    in {
      userExists = config.users.users ? alice;
      isNormalUser = config.users.users.alice.isNormalUser or false;
      autologinUser = config.services.getty.autologinUser;
      homeManagerConfigured = config.home-manager.users ? alice;
      # Ensure old username doesn't exist
      oldUserExists = config.users.users ? anuramat;
    };
    expected = {
      userExists = true;
      isNormalUser = true;
      autologinUser = "alice";
      homeManagerConfigured = true;
      oldUserExists = false;
    };
  };

  # Test username with special characters (should work)
  testUsernameWithDash = {
    expr = let
      config = (mkTestConfig "test-user").config;
    in {
      userExists = config.users.users ? test-user;
      autologinUser = config.services.getty.autologinUser;
    };
    expected = {
      userExists = true;
      autologinUser = "test-user";
    };
  };

  # Test username propagation to git config
  testUsernameInGitConfig = {
    expr = let
      config = (mkTestConfig "bob").config;
    in {
      gitUserName = config.home-manager.users.bob.programs.git.userName or "";
      gitUserEmail = config.home-manager.users.bob.programs.git.userEmail or "";
    };
    expected = {
      gitUserName = "Test User bob";
      gitUserEmail = "bob@example.com";
    };
  };

  # Test multiple usernames don't interfere
  testMultipleUsernames = {
    expr = let
      config1 = (mkTestConfig "user1").config;
      config2 = (mkTestConfig "user2").config;
    in {
      user1Exists = config1.users.users ? user1;
      user2Exists = config2.users.users ? user2;
      user1Autologin = config1.services.getty.autologinUser;
      user2Autologin = config2.services.getty.autologinUser;
    };
    expected = {
      user1Exists = true;
      user2Exists = true;
      user1Autologin = "user1";
      user2Autologin = "user2";
    };
  };

  # Test username in groups
  testUsernameGroups = {
    expr = let
      config = (mkTestConfig "testuser").config;
    in {
      hasWheelGroup = builtins.elem "wheel" (config.users.users.testuser.extraGroups or []);
      hasNetworkManagerGroup = builtins.elem "networkmanager" (config.users.users.testuser.extraGroups or []);
    };
    expected = {
      hasWheelGroup = true;
      hasNetworkManagerGroup = true;
    };
  };
}