{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter roles;
in
{
  lib.agents.commands = {
    pandoc_fix =
      let
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
      in
      {
        description = "fix a pandoc render issue";
        inherit text;
        withFM = prependFrontmatter text;
      };
    pandoc_clean =
      let
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
      in
      {
        description = "replace non-ascii characters with latex in markdown files";
        inherit text;
        withFM = prependFrontmatter text;
      };

    summarize_lectures =
      let
        text =
          let
            cmd = ''mkdir -p summaries; fd -e txt --max-depth=1 -x sh -c 'touch summaries/{.}.md ; echo "{} ---> ./summaries/{.}.md"''\''';
          in
          ''
            Summarize a set of lecture transcripts. Here are the transcripts in
            .txt files, and corresponding .md target paths initialized with
            empty files:

            !`${cmd}`

            Run `${roles.lecture-summarizer.name}` agents in parallel, one per
            file: provide each with path to a single transcript file, target
            path for the resulting summary, and additional information from the
            user (if any).

            Additional information:

            <context>
            $ARGUMENTS
            </context>
          '';

      in
      { };
  };
}
