{
  inputs,
  config,
  ...
}:
let
  inherit (inputs.self.consts.user) username name;
in
{
  services.openssh.settings.AllowUsers = [ username ];
  users.users.${username} = {
    description = name;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # root
    openssh.authorizedKeys = {
      inherit (config.lib.hosts) keyFiles;
    };
  };
}
