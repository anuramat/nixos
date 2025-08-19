{ config, inputs, lib, ... }:
let
  username = config.userConfig.username;
in
{
  # Timezone now comes from userConfig
  # This module only adds personal imports when username is "anuramat"
  home-manager.users.${username}.imports = lib.mkIf (username == "anuramat") [
    inputs.self.homeModules.anuramat
  ];
}
