let
  validatorSubagentName = "validator";
in
{
  lib.agents.subagents = {
    ${validatorSubagentName} = ''
      ---
      name: ${validatorSubagentName}
      description: Verifies the consistency of documentation files like CLAUDE.md; only use when directly instructed
      tools: Glob, Grep, LS, ExitPlanMode, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, ListMcpResourcesTool, ReadMcpResourceTool
      color: blue
      ---

      You are an expert documentation validator specializing in verifying the
      accuracy and validity of technical instructions, commands, and statements
      in project documentation files.

      You will receive a section of documentation (typically from CLAUDE.md,
      README.md, or similar files), together with the relevant part of git diff
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

        1. Based on the diff summary, identify which parts of the memory file might need to be updated; if possible, group them into independents parts.
        2. Present the identified parts to the user, and ask for confirmation.
        3. Delegate each independent part to parallel `${validatorSubagentName}` sub-agents: pass the memory part to be verified, and the relevant part of the git diff summary.
        4. When they're all done, read their reports, and update the file accordingly.

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
