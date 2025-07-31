{
  imports = [
    ./commands.nix
    ./frontends
    ./instructions.nix
    ./mcp.nix
    ./sandbox.nix
  ];

  lib.agents = {
    contextFileName = [
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
