{
  pkgs,
  user,
  unstable,
  config,
  ...
}:
let
  home = config.users.users.${user.username}.home;
  # TODO idk what the fuck to do with this, it's not good to leave this hardcoded
  sshKey = "${builtins.toString home}/.ssh/id_ed25519";
  # TODO add missing keys to trusted-public-keys
  substituters = [
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-python.cachix.org"
    "https://cache.iog.io"
  ] ++ user.substituters;
  nameToBuilder = name: {
    inherit sshKey;
    hostName = name;
    sshUser = user.builderUsername;
    system = pkgs.stdenv.hostPlatform.system;
  };
in
{
  nixpkgs.config = unstable.config;

  nix = {
    buildMachines = map nameToBuilder user.builderHostnames;
    distributedBuilds = !user.isBuilder;
    channel.enable = false;
    nixPath = [ ];
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      builders-use-substitutes = true; # (cache -> remote) instead of (cache -> local -> remote)
      inherit substituters; # used by default
      trusted-substituters = substituters; # merely allowed
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ] ++ user.trusted-public-keys;
    };
  };

  imports = if user.isBuilder then [ ./builder.nix ] else [ ];

  environment.systemPackages = [
    pkgs.nix-index
  ];
}
