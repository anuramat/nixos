{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
in
{
  lib.agents.commands = {
    iterate_spec = rec {
      description = "refine feature specification/implementation plan in files like SPEC.md/PLAN.md";
      withFM = prependFrontmatter text;
      text = ''
        Specification describes a feature that was not yet implemented.

        Properties of a good spec:

        - internal consistency: spec should not contradict itself
        - consistency with existing code: spec should not make incorrect assumptions about existing behaviour
        - completeness of decription/deterministic result: there should be one obvious way to implement the spec
        - quality of the end result: resulting implementation should be maintainable and correct

        Your task is to review the specification for implementation risks. You
        may inspect relevant parts of the codebase if needed to assess conflicts
        with existing behaviour.

        Identify and report:

        - ambiguities and contradictions in described feature behaviour
        - missing important edge cases
        - implicit contradictions with existing code behaviour or assumptions
        - behaviour that appears difficult to implement without major refactoring
        - inconsistent naming or terminology
        - anything else that is likely to cause problems in the future: bugs, maintainability issues, etc.

        Note:

        If the spec references components that don't exist, assume that they are
        a part of the feature descibed by the spec. If it's not already obvious
        from the spec, you must update the document to explicitly mention that
        they are a part of the feature.
      '';

    };
  };
}
