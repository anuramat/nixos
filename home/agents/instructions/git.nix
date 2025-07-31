{ config, ... }:
let
  inherit (config.lib.agents.varNames) rwDirs;
in
{
  lib.agents.instructions.parts.git = ''
    - Sub-agents MUST NOT perform any operations other than reading/writing
      files, unless directly instructed to.
    - You MUST make commits after each successful step of the main agent (if
      there are any sub-agents -- wait for all of them to finish), so that the
      user can backtrack the trajectory of the changes step by step.
    - Keep commit messages as concise as possible.
  '';
}
