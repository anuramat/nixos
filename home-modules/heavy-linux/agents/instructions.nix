{ config, lib, ... }:
let
  topHead = "#";
  sectionHead = "${topHead}#";
  head = "${sectionHead}#";

  mkInstructions =
    args:
    let

      inherit (lib)
        isList
        isString
        isAttrs
        ;
      when =
        cond: val:
        if cond then
          val
        else if isAttrs val then
          { }
        else if isString val then
          ""
        else if isList val then
          [ ]
        else
          throw "huh";
      for = agent: when (agent == args.agent);

      sections = {
        codestyle = ''
          Background:
          The user has to review the code thoroughly after the task is completed.
          The main limiting factor is the sheer amount of new/changed lines.
          You should aim for the smallest amount of code possible -- this will make it easier for the user to review the changes.

          - You MUST write concise code that prioritizes brevity and elegance over verbosity and caution.
          - You MUST NOT implement features that are neither explicitly requested by the user nor indirectly required.
          - You MUST avoid excessive comments, exhaustive error handling and edge case checks.
        '';

        general = ''
          - The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", "MAY" are to be interpreted as described in RFC 2119.
          - If you need tools that are not available on the system, you SHOULD use `nix run nixpkgs#packagename -- arg1 arg2 ...`.
          - To find required packages in `nixpkgs`, you SHOULD use `nh search $PACKAGE_NAME`${for "claude" "; if you need to find multiple packages, you MUST delegate package search to a sub-agent."}.
        ''
        + (for "claude" ''
          - You SHOULD use sub-agents (`Task` tool) whenever possible, preferably -- multiple sub-agents in parallel.
          - When presenting a plan to the user using `ExitPlanMode` tool, you SHOULD keep the plan under 10 lines -- only outline the high-level steps.
        '');

        git = ''
          - You MUST make commits after each step, so that the user can backtrack the trajectory of the changes step by step.
          - Keep commit messages as concise as possible.
        '';

        workflow = ''
          ${head} Acceptance criteria identification

          Before starting ANY task you MUST explicitly identify acceptance criteria,
          and add the corresponding check as a final step to your plan/todo list${
            if (args.planningTool != null) then " using the `${args.planningTool}` tool" else ""
          }.

          After finishing the task, you MUST verify that the solution meets the acceptance criteria.
          If some criteria are NOT met, you MUST continue iterating on the problem, until ALL the acceptance criteria are met.
          The task CAN NOT be considered complete until ALL the acceptance criteria are met.

          Typical acceptance criteria:

          | Task context       | Acceptance criterion       |
          | ------------------ | -------------------------- |
          | Project with tests | All relevant tests pass    |
          | Flake              | `nix build` succeeds       |
          | Flake with checks  | `nix flake check` succeeds |
          | Flake with an app  | `nix run` succeeds         |
          | Non-development    | None                       |
        '';
      };

      prependTitle = body: lib.concatStringsSep "\n" ([ "${topHead} Global instructions\n" ] ++ body);
    in
    sections |> lib.mapAttrsToList (n: v: "${sectionHead} ${n}\n\n" + v) |> prependTitle;
in
{
  lib.agents.instructions = {
    generic = mkInstructions {
      agent = null;
      planningTool = null;
    };
    claude = mkInstructions {
      agent = "claude";
      planningTool = "TodoWrite";
    };
    codex = mkInstructions {
      agent = "codex";
      planningTool = "update_plan";
    };
  };
}
