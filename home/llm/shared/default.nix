{
  imports = [
    ./mcp.nix
    ./commands.nix
    ./instructions.nix
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
