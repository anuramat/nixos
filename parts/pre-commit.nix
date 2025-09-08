{ pkgs, ... }:
{
  # TODO nix fmt; wait for https://github.com/cachix/git-hooks.nix/issues/287
  # See https://flake.parts/options/git-hooks-nix.html for flake-parts git-hooks.nix documentation
  settings.hooks = {
    treefmt.enable = true;
    flake-inputs-freshness = {
      enable = true;
      name = "Check flake inputs freshness";
      entry = "${pkgs.writeShellScriptBin "flake-inputs-check" ''
        #!/usr/bin/env bash
        echo "pre commit flake inputs check"
        prev="$(mktemp)"
        cat ./flake.nix >"$prev"
        just flake &>/dev/null
        diff "$prev" ./flake.nix || exit 1
      ''}/bin/flake-inputs-check";
      files = "^flake\\.nix$";
      language = "system";
    };
  };
}
