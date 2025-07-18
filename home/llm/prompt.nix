{ lib, varNames }:
let
  parts = {
    protocol = ''
      You MUST adhere to the following two-stage development protocol:

      ### Stage 1: Test command identification

      Before starting ANY task you MUST explicitly identify a "test command". Examples
      of typical cases:

      - if there are any tests: you MUST run tests
      - nix flake: you MUST run `nix build`; `nix run` -- if applicable
      - minor proof-of-concept script -- you MUST demonstrate that it works

      When working on a big feature, you MUST write tests first (test-driven
      development).

      ### Stage 2: Dev-test loop

      You MUST repeat the "development" and "test" steps until you succeed:

      1. Development: implement the solution, a part of the solution, or fix a
         problem. You MUST NOT disable problematic features.
      2. Test: run the "testing command".
      3. If the task is not completed, or the "test command" fails, go to step 1.

      Only consider the task complete, when the "test command" succeeds.
    '';

    general = ''
      - The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
        "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be
        interpreted as described in RFC 2119.
      - You MUST NOT use anything other than ASCII characters in all replies and
        generated files
      - You SHOULD use parallel sub-agents whenever possible -- this saves time,
        tokens, and keeps the context clean.
      - You MUST NOT blindly trust project memory, as it gets outdated quick -- the
        source of truth is the code.
      - If you need tools that are not available on the system, you SHOULD use
        `nix run nixpkgs#packagename -- arg1 arg2 ...`. You can use NixOS MCP server
        to locate the required package.
      - You are running in a `bubblewrap` sandbox. Most of the paths outside of the
        current working directory are mounted in read-only mode. You can find the
        read-write mounted directories in the `${varNames.rwDirs}` environment variable.
    '';

    codestyle = ''
      Background: the user can't trust AI generated code/comments, thus he has to
      always review it thorouhgly. The main limiting factor is the amount of
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

    git = ''
      - You MUST make commits after each successful step, so that the user can
        backtrack the trajectory of the changes step by step.
      - Keep commit messages as concise as possible.
    '';

    # TODO proper name for "math block" and inline math

    markdown = ''
      - For mathematical symbols, you MUST use Markdown inline math `$...$` and math
        blocks `$$...$$`
      - Math block delimiters MUST be on separate lines like in this example:
        ```markdown
        Paragraph before. Inline math is used like this: $\alpha$.

        $$
        \text{example}
        $$

        Paragraph after. Notce the blank lines between paragraphs, and math block
        delimiters `$$` being on separate lines.
        ```
      - You SHOULD prefer:
        - math blocks to inline math, whenever the equation is big
        - multi-line math blocks with `gathered` or `aligned` environments to multiple
          math blocks in a row
    '';
  };
in
parts |> lib.attrsets.mapAttrsToList (n: v: "## ${n}\n" + v) |> lib.concatStringsSep "\n"
