{
  config,
  pkgs,
  machines,
  ...
}:
let
  # TODO add missing keys to trusted-public-keys
  substituters = [
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-python.cachix.org"
    "https://cache.iog.io"
  ] ++ machines.substituters;
  inherit (config.users.users.${config.me}) home;
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
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
      ] ++ machines.trusted-public-keys;
    };

    buildMachines = map (x: {
      # sshKey and sshUser are ignored for some reason
      # <https://github.com/NixOS/nix/issues/3423>
      # for now add those to /root/.ssh/config
      sshUser = machines.builderUsername;
      sshKey = "${home}/.ssh/id_ed25519";
      hostName = x.name;
      system = x.platform;
      protocol = "ssh-ng";
    }) machines.builders;

  };

  environment.systemPackages = [
    pkgs.nix-index
  ];
}
