{ config, ... }:
{
  imports = [
    ./commands.nix
    ./frontends
    ./instructions
    ./mcp.nix
    ./sandbox.nix
  ];

  # terminology:
  # context -- text automatically loaded by the agent
  # instructions -- global context

  lib.agents = {
    mainContextFile = "AGENT.md";

    contextFiles = [
      "CRUSH.md"
      "GEMINI.md"
      "CLAUDE.md"
      "AGENTS.md"
      "AGENT.md"
    ];

    varNames = {
      rwDirs = "RW_DIRS";
      agentName = "AGENT";
    };
  };
}
