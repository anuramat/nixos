{
  user,
  consts,
  config,
  inputs,
  lib,
  ...
}:
let
  # TODO add missing keys to trusted-public-keys
  substituters = [
    "https://cache.iog.io"
    "https://cache.nixos.org"
    "https://cuda-maintainers.cachix.org"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixpkgs-python.cachix.org"
  ]
  ++ config.lib.hosts.substituters;
  keyPath = "${config.users.users.${user.username}.home}/.ssh/id_ed25519";
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  programs.nh = {
    enable = true;
  };

  nix = with lib.attrsets; {
    channel.enable = false;

    # add all inputs to registry
    registry = mapAttrs (n: v: { flake = v; }) inputs;
    # and then to nixpath (required by haskell stack)
    nixPath = mapAttrsToList (n: v: "${n}=${v.outPath}") inputs;
    # note that input names matter now

    settings = {
      secret-key-files = "/etc/nix/cache.pem";
      fallback = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      builders-use-substitutes = true; # (cache -> remote) instead of (cache -> local -> remote)
      inherit substituters; # used by default
      trusted-substituters = substituters; # merely allowed
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      ]
      ++ config.lib.hosts.trusted-public-keys;
    };

    buildMachines = lib.mapAttrsToList (n: v: {
      # sshKey and sshUser are ignored for some reason BUG
      # <https://github.com/NixOS/nix/issues/3423>
      # for now add those to /root/.ssh/config
      # ```
      # Host anuramat-ll7
      #         IdentitiesOnly yes
      #         IdentityFile /home/anuramat/.ssh/id_ed25519
      #         User builder
      #         ConnectTimeout 3
      # ```
      # TODO speedFactor, maxJobs
      sshUser = consts.builderUsername;
      sshKey = keyPath;
      hostName = n;
      system = v.system;
      protocol = "ssh-ng";
    }) config.lib.hosts.builders;
  };
}
