{ ... }:
{
    # TODO nix fmt; wait for https://github.com/cachix/git-hooks.nix/issues/287
  settings.hooks = {
    treefmt.enable = true;
  };
}
