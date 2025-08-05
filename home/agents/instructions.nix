{ config, lib, ... }:
let
  inherit (config.lib.agents) mainContextFile;
  topHead = "#";
  sectionHead = "${topHead}#";

  head = "${sectionHead}#";

  mkInstructions =
    let
      prependTitle = body: lib.concatStringsSep "\n" ([ "${topHead} Global instructions\n" ] ++ body);
    in
    sections: sections |> lib.mapAttrsToList (n: v: "${sectionHead} ${n}\n\n" + v) |> prependTitle;

  text = mkInstructions sections;

  sections =
    let
      inherit (config.lib.agents.varNames) rwDirs;
    in
    {
      codestyle = ''
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

      subagents = ''
        - You SHOULD use parallel sub-agents whenever possible -- this saves time,
          tokens, and keeps the context clean.
        - Sub-agents MUST NOT perform any operations other than reading/writing
          files, unless directly instructed by the user.
      '';

      general = ''
        - The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
          "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be
          interpreted as described in RFC 2119.
        - You MUST NOT use anything other than ASCII characters in all replies and
          generated files
        - You MUST NOT blindly trust project memory files, as they get outdated
          quick -- the source of truth is the code.
        - If you need tools that are not available on the system, you SHOULD use
          `nix run nixpkgs#packagename -- arg1 arg2 ...`. You can use NixOS MCP server
          to locate the required package.
        - You are running in a `bubblewrap` sandbox. Most of the paths outside of the
          current working directory are mounted in read-only mode. You can find the
          read-write mounted directories in the `${rwDirs}` environment variable.
      '';

      git = ''
        - You MUST make commits after each step, so that the user can backtrack
          the trajectory of the changes step by step.
        - Keep commit messages as concise as possible.
      '';

      # TODO proper name for "math block" and inline math
      markdown = ''
        For mathematical symbols, you MUST use Markdown inline math `$...$` and
        display (block) math `$$...$$`.

        You MUST NOT use `gather` or `align` -- they won't work, because markdown
        math blocks are wrapped in math mode already; use `gathered` or `aligned`
        instead.

        Example:

        ```markdown
        Inline math is used like this: $\alpha$. Use it sparingly; for anything
        more than a few symbols, you MUST use a separate block:

        $$
        E = mc^2
        $$

        Notce the blank lines between paragraphs, and math block delimiters `$$`
        on separate lines. The block delimiters MUST be the only symbols in the
        line.
        ```
      '';

      workflow = ''
        You MUST adhere to the following development protocol:

        ${head} Preparation: Acceptance criteria identification

        Before starting ANY task you MUST explicitly identify acceptance
        criteria, unless it's directly specified. Typical cases, in pairs of situation -- :

        | Task context       | Acceptance criterion       |
        | ------------------ | -------------------------- |
        | Project with tests | All relevant tests pass    |
        | Flake              | `nix build` succeeds       |
        | Flake with checks  | `nix flake check` succeeds |
        | Flake with an app  | `nix run` succeeds         |
        | Non-development    | None                       |

        ${head} Test:

        You SHOULD write tests, if possible -- before implementing the feature
        (test-driven development).

        ${head} Development loop

        You MUST iterate using the following "development" and "verification" steps
        until you succeed:

        1. Development: implement the solution, a part of the solution, or fix a
           problem; then proceed to verification.
        2. Verification: verify that the solution meets the acceptance criteria.
           - If the criteria are met, the task is complete.
           - Otherwise, go back to step 1 -- iterate again on the solution.

        The task can be considered complete ONLY if the acceptance criteria
        are met.
      '';

      usage =
        "You are provided special agent-focused CLI tools, that you can use with your bash tool:"
        + lib.concatStringsSep "\n"
        + lib.agents.usage;
    };
in
{
  lib.agents.instructions = {
    inherit
      sections
      head # TODO rename
      mkInstructions
      text
      ;
    path = "${config.home.homeDirectory}/${config.xdg.configFile.${mainContextFile}.target}";
  };
  xdg.configFile.${mainContextFile} = { inherit text; };
}
