{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.lib.hosts) keyFiles;
  inherit (inputs.self.consts.builder) username;
in
{
  config = lib.mkIf inputs.self.hosts.${config.networking.hostName}.builder {
    users.users.${username} = {
      isNormalUser = true;
      createHome = false;
      home = "/var/empty";
      group = username;
      openssh.authorizedKeys = {
        inherit keyFiles;
      };
    };
    users.groups.${username} = { };
    services.openssh.settings.AllowUsers = [
      username
    ];
  };
}
