{ ... }:
{
  # TODO nix fmt; wait for https://github.com/cachix/git-hooks.nix/issues/287
  # https://flake.parts/options/git-hooks-nix.html
  settings.hooks.treefmt.enable = true;
}
