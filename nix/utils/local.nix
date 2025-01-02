{
  pkgs,
  user,
  config,
  ...
}:
let
  home = config.users.users.${user.username}.home;
  sshKey = "${builtins.toString home}/.ssh/id_ed25519";
in
{
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      inherit sshKey;
      hostName = "anuramat-ll7"; # TODO change
      sshUser = "remotebuild";
      system = pkgs.stdenv.hostPlatform.system;
    }
  ];
}
