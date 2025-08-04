{ config, lib, ... }:
# TODO tmux test bench
# TODO refactoring
{
  lib.agents.roles = {
    testmode =
      let
        inherit (config.lib.agents) prependFrontmatter;
        name = "testmode";
        description = "test mode";
        text = '''';
      in
      {
        inherit name description;
        readonly = true;
        withFM = prependFrontmatter text;
      };
  };
}
