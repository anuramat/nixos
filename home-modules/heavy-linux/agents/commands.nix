{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
in
{
  lib.agents.commands = {
    explain_diff = rec {
      description = "explain a diff in a human-friendly way, so that the user can easily review it";
      withFM = prependFrontmatter text;
      text = ''
        Help me review this diff by providing a review guide:

        I will open it side by side with code, go through the review
        instructions top to bottom, and read mentioned files.

        Review instructions must be structured as a list of bullet points: each
        point must mention a few files and a short explanation of the changes.

        Order should be such that I can comfortably learn what changed in this
        diff, and incrementally build a mental model of the changes.

        You must omit the changes to tests from the review guide.

        After the bullet points, provide a concise summary of the changes.
      '';
    };
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
