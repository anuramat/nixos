{
  lib.agents.parts.codestyle = ''
    Background: the user can't trust AI generated code/comments, thus he has to
    always review it thorouhgly. The main limiting factor is the sheer amount of
    new/changed lines. Thus:

    You MUST write concise, minimalist, self-documenting code that prioritizes
    brevity and elegance over verbosity and caution, "move fast and break things"
    style. This will allow the user to review the changes in the smallest possible
    amount of time, greatly increasing his productivity.

    - Prefer:
      - Compact constructs: oneliners, lambdas, pipes, list comprehensions
      - Functional style
      - Language specific preferences:
        - Nix: `let ... in`, helper lambdas, `inherit`, `with`
    - Avoid:
      - Bloat, boilerplate, verbosity
      - Exhaustive error handling
      - Unnecessary edge case checks
      - Excessive comments
      - Bloated code formatting with a lot of newlines
    - Arcane but effective solutions are welcome

    With complex multi-step problems you SHOULD prefer a two stage approach: write
    verbose code, then refactor it to meet the code style guidelines.
  '';
}
