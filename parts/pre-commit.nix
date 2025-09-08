{ pkgs, ... }:
{
  # TODO nix fmt; wait for https://github.com/cachix/git-hooks.nix/issues/287
  # https://flake.parts/options/git-hooks-nix.html
  settings.hooks = {
    treefmt.enable = true;
    flake-inputs-freshness = {
      enable = true;
      name = "Check flake inputs freshness";
      entry = pkgs.writeShellScript "flake-inputs-check" ''
        #!/usr/bin/env bash
        echo "pre commit flake inputs check"
        prev="$(mktemp)"
        cat ./flake.nix >"$prev"
        just flake &>/dev/null
        diff "$prev" ./flake.nix || exit 1
      '';
      files = "^flake\\.nix$";
      language = "system";
    };
  };
}
