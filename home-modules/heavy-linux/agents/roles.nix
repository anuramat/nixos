{ config, lib, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
  inherit (lib) trim replaceStrings;
  flatten = x: x |> replaceStrings [ "\n" ] [ " " ] |> trim;
  h1 = "##";
in
{
  lib.agents.roles = {
    researcher = {
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

# researcher agent, that performs web search (using the provided tool), and
# figures out the specified question, eg: exact name of the package in nixpkgs
# that provides given software; canonical way to do something in nix; latest
# version of a given project; link to the latest binary; and so on
