final: prev: {
  duckduckgo-mcp-server = prev.python312.pkgs.buildPythonApplication rec {
    pname = "duckduckgo-mcp-server";
    version = "0.1.1";
    format = "pyproject";
    src = prev.python312.pkgs.fetchPypi {
      pname = "duckduckgo_mcp_server";
      inherit version;
      hash = "sha256-1vSPTLQjTennFuh/fUmqVGN+vEo3AOz9BfJgaWRjwOw=";
    };
    build-system = with prev.python312.pkgs; [
      hatchling
    ];
    dependencies = with prev.python312.pkgs; [
      beautifulsoup4
      httpx
      mcp
    ];
    doCheck = false;
    dontCheckRuntimeDeps = true;
    meta = {
      description = "A Model Context Protocol server that provides web search capabilities through DuckDuckGo";
      homepage = "https://github.com/nickclyde/duckduckgo-mcp-server";
      license = prev.lib.licenses.mit;
      mainProgram = "duckduckgo-mcp-server";
    };
  };
}
