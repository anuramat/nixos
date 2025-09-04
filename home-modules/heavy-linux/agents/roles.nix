{ config, lib, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
  inherit (lib) trim replaceStrings;
  flatten = x: x |> replaceStrings [ "\n" ] [ " " ] |> trim;
  h1 = "##";
  h2 = "###";
in
{
  lib.agents.roles = {
    researcher = {
      # idea -- web search for best practices, packages, etc
      name = "researcher";
      description = flatten ''
        do not use this for now, work in progress
      '';
      withFM = prependFrontmatter ''
        ${h1} Header

        ${h1} Success criteria
      '';
    };

  };
}
