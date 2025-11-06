{
  config,
  pkgs,
  ...
}:
let
  mcp = {
    # ddg = config.lib.agents.mcp.raw.ddg // {
    #   type = "stdio";
    # };
  };
  options = {
    context_paths = [
      "AGENTS.md"
      (pkgs.writeText "AGENTS.md" config.lib.agents.instructions.generic)
    ];
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  crush = pkgs.writeShellScriptBin "crush" ''
    pathEncoded=$(pwd | base64)
    dir="${config.xdg.stateHome}/crush/$pathEncoded"
    $XDG_BIN_HOME/crush-bin -D "$dir" "$@"
  '';

  pkg = config.lib.agents.mkPackages {
    package = crush;
    args = [ "--yolo" ];
    agentDir = "crush";
  };

in

{
  home = {
    packages = [ pkg ];
    activation = {
      crushConfig = config.lib.home.json.set {
        inherit
          mcp
          options
          ;
      } configPath;
    };
  };
}
