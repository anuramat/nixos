let
  validator = "validator";
in
{
  lib.agents.subagents = {
    ${validator} = ''
      ---
      name: ${validator}
      description: Use this agent when you need to verify the accuracy and validity of instructions, commands, or statements in documentation files like CLAUDE.md, README files, or similar project documentation. Examples: <example>Context: User has updated their CLAUDE.md file with new build commands and wants to ensure they're still valid. user: 'I've updated the build section in CLAUDE.md, can you check if the nix build command still works?' assistant: 'I'll use the instruction-validator agent to verify the build commands in your CLAUDE.md file' <commentary>Since the user wants to validate instructions in documentation, use the instruction-validator agent to check command validity.</commentary></example> <example>Context: User is reviewing project documentation before a release. user: 'Please verify that all the commands and file paths mentioned in our project documentation are still correct' assistant: 'I'll use the instruction-validator agent to systematically check all commands and paths in your documentation' <commentary>The user needs comprehensive validation of documentation accuracy, perfect use case for the instruction-validator agent.</commentary></example>
      tools: Glob, Grep, LS, ExitPlanMode, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, ListMcpResourcesTool, ReadMcpResourceTool
      color: blue
      ---

      You are an expert documentation validator specializing in verifying the
      accuracy and validity of technical instructions, commands, and statements
      in project documentation files.

      You will receive a section of documentation (typically from CLAUDE.md,
      README.md, or similar files) and must verify:

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
  };
  lib.agents.prompts = {
    fixdoc = ''
      ---
      description: fix a pandoc render issue
      ---

      I want you to figure out why this markdown file doesn't get rendered
      with my `pandoc` script. Usually, the problem is in the LaTeX code in
      the math blocks. Use the command `render input.md output.pdf`, read the
      error message, edit the file, and try to render again. Test command --
      aforementioned `render`. 

      - Do not try to debug `pandoc`, LaTeX engine itself, or the `render`
        script -- it's practically never the issue.
      - Error messages will show confusing line numbers -- they correspond to
        an intermediate representation, and thus are irrelevant in the context
        of fixing the markdown file. You can ignore the line numbers. Focus on
        the LaTeX code mentioned in the error message, and grep for it (if
        available).
    '';
    asciify =
      let
        cmd = "LC_ALL=C rg '[^[:print:]]' --line-number";
      in
      ''
        ---
        description: replace non-ascii characters with latex in markdown files
        ---

        I want you to replace all non-ASCII characters in markdown files with
        corresponding inline math `$...$` or math blocks `$$...$$`. If you find
        something like umlauts in german names, you should replace them with
        corresponding ASCII equivalents, eg `Jäger` becomes `Jaeger`.

        Here is the list of non-ASCII characters found in the files:

        !`${cmd}`

        Do the necessary replacements, and then verify that everything was
        replaced, using this command:

        `${cmd}`
      '';
    memupdate =
      let
        memfile = "CLAUDE.md";
        commit_cmd = "git log -1 --format=%H ${memfile}";
        shortdiff_cmd = "${commit_cmd} | xargs git diff --numstat";
      in
      ''
        ---
        description: memory file update guided by git history
        ---

        I want you to update ${memfile}, since the project changed a lot.

        Last commit where the memory was updated is:

        !`${commit_cmd}`

        and the corresponding diff summary is:

        !`${shortdiff_cmd}`

        1. Based on the diff summary, identify which parts of the memory file might need to be updated; group them into independents parts.
        3. Present the parts to the user, and ask for confirmation.
        4. Delegate verification of each independent part to parallel `${validator}` sub-agents.
        5. When they're all done, read their reports, and update the file accordingly.

        Commit the changes with the message:

        ```gitcommit
        docs(${memfile}): update

        <short_summary>
        ```

        where `<short_summary>` is a short description of the changes in the
        project that are now reflected in the memory file.
      '';
  };
}
