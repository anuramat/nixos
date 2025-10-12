{ config, ... }:
let
  inherit (config.lib.agents) prependFrontmatter;
in
# TODO remove withFM
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
    plan = rec {
      description = "plan the changes";
      withFM = prependFrontmatter text;
      text = ''
        I want you to provide a plan for the following task:

        $ARGUMENTS

        You can read files and search the web, but do not edit any files yet.
        Gather the required information and provide a concise plan of the
        changes required to accomplish the task. Provide key code snippets, if
        applicable.
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
