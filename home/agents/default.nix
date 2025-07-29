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
      "GEMINI.md"
      "CLAUDE.md"
      "AGENTS.md"
    ];

    varNames = {
      rwDirs = "RW_DIRS";
      agentName = "AGENT";
    };
  };
}
