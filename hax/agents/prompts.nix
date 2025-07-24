{
  memchk = ''
    ---
    description: memory file update guided by direct verification
    ---

    I want you to update CLAUDE.md, since the project changed a lot.

    Go through CLAUDE.md and partition the statements/instructions into parts,
    that correspond to independent parts of the project.

    For each set of statements/instructions and corresponding part of the
    project, run a parallel agent and verify every statement/instruction, by
    looking up the relevant files and their contents:

    - Statements should correctly reflect the state of the project.
    - Instructions should be valid: for example, if instruction tells you to
      use a makefile target that was renamed/deleted/moved to a shell script --
      update it accordingly.
  '';
  render = ''
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
      description: replacement of non-ascii characters with latex in markdown files
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

      I want you to check if the project memory in ${memfile} is significantly
      outdated, and if so -- update it.

      Last commit where the memory was updated is:

      !`${commit_cmd}`

      and the corresponding diff summary is:

      !`${shortdiff_cmd}`

      In case there are significant changes -- ones that either make information in
      ${memfile} invalid, or are important enough to warrant new entries in the
      file -- explore the necessary files, and edit ${memfile}.

      If you make any changes to the memory file, commit the changes with the
      message:

      ```gitcommit
      docs(${memfile}): update

      <short_summary>
      ```

      where `<short_summary>` is a short description of the changes in the
      project that are now reflected in the memory file.
    '';
}
