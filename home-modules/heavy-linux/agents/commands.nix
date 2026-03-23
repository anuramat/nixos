{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
in
{
  lib.agents.commands = {
    iterate_spec = rec {
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
        - anything else that is likely to cause incorrect or error-prone implementation

        Output format:

        - group findings into two categories:
          - certain problems: self-contradictions, logical flaws
          - potential problems: ambiguities, missing cases, contradictions with
            existing code
        - for each category, provide a list of concise bullet points describing
          the issues found

        Constraints:

        - if referenced components do not exist in the codebase, assume they will be implemented later and do not flag this as an issue
        - focus only on specification correctness and clarity, not technical design
        - do not suggest implementation solutions
        - do not implement anything in the code
      '';

      # TODO "if possible, assume the simplest behaviour that satisfies the spec when something is ambiguous"
      # TODO add a follow-up command to fix the spec based on the analysis:
      # I edited the spec in the last commit; review the last commit and list the remaining issues that were not fixed
    };
  };
}
