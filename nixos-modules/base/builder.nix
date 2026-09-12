{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.lib.hosts) builderUsername keyFiles;
in
{
  config = lib.mkIf inputs.self.hosts.${config.networking.hostName}.builder {
    users.users.${builderUsername} = {
      isNormalUser = true;
      createHome = false;
      home = "/var/empty";
      group = builderUsername;
      openssh.authorizedKeys = {
        inherit keyFiles;
      };
    };
    users.groups.${builderUsername} = { };
    services.openssh.settings.AllowUsers = [
      builderUsername
    ];
  };
}
