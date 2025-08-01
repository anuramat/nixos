{ config, lib, ... }:
# TODO tmux test bench
# TODO refactoring
{
  lib.agents.roles = {
    validator =
      let
        inherit (config.lib.agents) prependFrontmatter;
        context = config.lib.agents.contextFiles |> lib.concatStringsSep ", ";
        name = "validator";
        description = "Verifies the consistency of documentation files like AGENTS.md; only use when directly instructed";
        text = ''
          You are an expert documentation validator specializing in verifying the
          accuracy and validity of technical instructions, commands, and statements
          in project documentation files.

          You will receive a section of documentation (typically from ${context}
          or similar files), together with the relevant part of git diff
          summary since the last update of documentation, and must verify:

          - Verify file/directory existence and structure
          - Verify existence of scripts and `make` targets
          - Statements should correctly reflect the state of the project.
            - Cross-reference claims against actual codebase state

          ## Output Format

          Provide a concise structured report with:

          - ERRORS: Detailed list of inaccurate parts of documentation, and the
            corresponding proposed change of the documentation
          - WARNINGS: Potentially outdated or ambiguous statements
        '';
      in
      {
        inherit name description;
        readonly = true;
        withFM = prependFrontmatter text;
      };
  };
}
