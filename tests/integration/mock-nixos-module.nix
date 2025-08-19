# Mock NixOS module for testing username configuration
{ username, lib, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "Test user ${username}";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  services.getty.autologinUser = username;

  # Mock home-manager integration
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    programs.git = {
      enable = true;
      userName = "Test User ${username}";
      userEmail = "${username}@example.com";
    };
  };
}
