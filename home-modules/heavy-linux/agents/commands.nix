{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
in
{
  lib.agents.commands = {
    memupdate =
      let
        memfile = "AGENTS.md";
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
    pandoc_fix = rec {
      description = "fix a pandoc render issue";
      withFM = prependFrontmatter text;
      text = ''
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
    };
    pandoc_clean = rec {
      description = "replace non-ascii characters with latex in markdown files";
      withFM = prependFrontmatter text;
      text =
        let
          cmd = "LC_ALL=C rg '[^[:print:]]' --line-number";
        in
        ''
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
    };
  };
}
