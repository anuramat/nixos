{ config, ... }:
let
  inherit (config.lib.agents.varNames) rwDirs;
in
{
  lib.agents.parts.general = ''
    - The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
      "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be
      interpreted as described in RFC 2119.
    - You MUST NOT use anything other than ASCII characters in all replies and
      generated files
    - You SHOULD use parallel sub-agents whenever possible -- this saves time,
      tokens, and keeps the context clean.
    - You MUST NOT blindly trust project memory files, as they get outdated
      quick -- the source of truth is the code.
    - If you need tools that are not available on the system, you SHOULD use
      `nix run nixpkgs#packagename -- arg1 arg2 ...`. You can use NixOS MCP server
      to locate the required package.
    - You are running in a `bubblewrap` sandbox. Most of the paths outside of the
      current working directory are mounted in read-only mode. You can find the
      read-write mounted directories in the `${rwDirs}` environment variable.
  '';
}
