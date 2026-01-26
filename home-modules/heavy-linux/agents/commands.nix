{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
  memupdate =
    memfile:
    let
      commit_cmd = "git log -1 --format=%H ${memfile}";
      shortdiff_cmd = "${commit_cmd} | xargs git diff --numstat";
    in
    rec {
      description = "memory file update guided by git history";
      withFM = prependFrontmatter text;
      text = ''
        I want you to update ${memfile}, since the project changed a lot.

        Last commit where the memory was updated is:

        !`${commit_cmd}`

        and the corresponding diff summary is:

        !`${shortdiff_cmd}`

        1. Based on the diff summary, identify which parts of the memory
           file might need to be updated; if possible, group them logically.
        2. Present the identified parts to the user.
        3. Go through the parts one by one, and update the file. You should
           read corresponding files if necessary.

        Commit the changes with the message:

        ```gitcommit
        docs(${memfile}): update

        <short_summary>
        ```

        where `<short_summary>` is a short description of the changes in the
        project that are now reflected in the memory file.
      '';
    };
in
{
  lib.agents.commands = {
    agupd = memupdate "AGENTS.md";
    clupd = memupdate "CLAUDE.md";
    specfix = rec {
      description = "refine feature specification in SPEC.md";
      withFM = prependFrontmatter text;
      text = ''
        @SPEC.md contains a specification of a feature I want to implement. It
        describes desired behaviour: motivation, use cases, user-visible
        behaviour, edge cases, and terminology.

        Your task is to review the specification for implementation risks. You
        may inspect relevant parts of the codebase if needed to assess conflicts
        with existing behaviour. Do not explore unrelated code.

        Identify and report:

        - ambiguities and contradictions in described feature behaviour
        - missing important edge cases
        - implicit contradictions with existing code behaviour or assumptions
        - behaviour that appears difficult to implement without major refactoring
        - inconsistent naming or terminology
        - any other issues likely to cause incorrect or error-prone implementation

        Output format:

        - group findings by category
        - for each issue:
          - quote the relevant part of the specification
          - provide a concise explanation of the risk
          - assign a severity: low / medium / high

        Constraints:

        - if referenced components do not exist in the codebase, assume they will be implemented later and do not flag this as an issue
        - focus only on specification correctness and clarity, not technical design
        - do not suggest implementation solutions
        - do not implement anything in the code
      '';
    };
    planmk = rec {
      description = "plan the changes";
      withFM = prependFrontmatter text;
      text = ''
        I want you to provide a plan for the following task:

        $ARGUMENTS

        You can read files and search the web, but do not edit any files yet.
        Gather the required information and provide a concise plan of the
        changes required to accomplish the task. Provide key code snippets, if
        applicable.
      '';
    };
  };
}
