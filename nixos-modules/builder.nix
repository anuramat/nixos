{
  config,
  inputs,
  ...
}:
let
  inherit (inputs.self.consts) builderUsername;
in
{
  users.users.${builderUsername} =
    assert !config.nix.distributedBuilds; # TODO are we sure this will always be XOR
    {
      isNormalUser = true; # TODO maybe not?
      createHome = false;
      home = "/var/empty";
      group = builderUsername;
      openssh.authorizedKeys = {
        inherit (config.lib.hosts) keyFiles;
      };
    };
  users.groups.${builderUsername} = { }; # TODO huh
  services.openssh.settings.AllowUsers = [
    builderUsername
  ];
}
