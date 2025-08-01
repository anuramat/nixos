{ config, lib, ... }:
# WARN context files are hardcoded in lua/avante/utils/prompts.lua: AGENTS, CLAUDE, OPENCODE, ...
# TODO patch
let
  inherit (config.lib) agents;
  inherit (lib) mapAttrs;

  shortcuts =
    agents.commands
    |> mapAttrs (
      n: v: with v; {
        inherit description;
        name = n;
        prompt = text;
        details = text;
      }
    );

in
{
  # TODO mcphub
  programs.nixvim.plugins = {
    avante.settings = {
      inherit shortcuts;
      system_prompt = agents.instructions.text;
      provider = "copilot";
      providers = {
        copilot = {
          # model = "claude-sonnet-4";
          model = "gpt-4.1";
        };
      };
    };
  };
}
