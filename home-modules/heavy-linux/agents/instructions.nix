{ lib, config, ... }:
let
  topHead = "#";
  sectionHead = "${topHead}#";
  head = "${sectionHead}#";
  username = config.home.username;

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
      # TODO make it take a list -- set of agent names

      sections = {
        codestyle = ''
          Background:
          The user has to review the code thoroughly after the task is completed.
          The main limiting factor is the sheer amount of new/changed lines.
          You should aim for the smallest possible amount of code that does the job -- this will make it easier for the user to review the changes.
          This does not apply to temporary files (e.g. debugging/test scripts), i.e. you can write as much code as you need in temporary files.

          - You MUST write concise code that prioritizes brevity and elegance over verbosity and caution.
          - You MUST NOT implement features that are neither explicitly requested by the user nor indirectly required.
          - You MUST avoid excessive comments, exhaustive error handling and edge case checks.
        '';

        nix = ''
          - To find required packages in `nixpkgs`, you SHOULD use `nh search $PACKAGE_NAME`.
          - You MUST NOT use `nix search`, it's slow and unstable; instead, use `nh search`
          - To explore NixOS options, you SHOULD use `nixos-option $OPTION_NAME`

          Examples:

          <example>
            <user>How do I configure git in home-manager?</user>
            <assistant>I am going to use `nixos-option` to find the corresponding option</assistant>
            <bash_command>home-manager.users.${username}.programs.git</bash_command>
            <bash_output>
            This attribute set contains:
            aliases
            attributes
            ...
            </bash_output>
          </example>
          <explanation>
            Assistant uses `nixos-option` to explore the options available for configuring git in home-manager.
          </explanation>

          <example>
            <user>solve the following task ...</user>
            <assistant>... I am going to use `<command_name>` to ...</assistant>
              <bash_command><command_name> ...</bash_command>
              <bash_output><command_name> not found</bash_output>
            <assistant>I am going to use `nh` to find the corresponding package</assistant>
              <bash_command>nh search <command_name></bash_command>
              <bash_output>
                ...
                <package_name> (<version>)
                  <short_description>
                  Homepage: <url>
                  Defined at: <path>
                ...
              </bash_output>
            <bash_command><command_name> ...</bash_command>
          </example>
          <explanation>
          Assistant first tries to run the command, and because it's not found, it uses `nh search` to find the corresponding package.
          </explanation>
        '';

        sandbox = ''
          You are running in a sandbox. The path to sandbox script is stored in
          environment variable `${config.lib.agents.varNames.sandboxWrapperPath}`.

          Some commands may not work as expected. If you suspect that a command
          is not working because of the sandbox, you MAY ask the user to run the
          command manually.
        '';

        general = ''
          - The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", "MAY" are to be interpreted as described in RFC 2119.
          - You MUST NOT do "band-aid" fixes -- ALWAYS fix the root cause of the problem.
          - If you need tools that are not available on the system, you SHOULD use `nix run nixpkgs#package_name -- arg1 ...`.
        ''
        + (for "claude" ''
          - When presenting a plan to the user using `ExitPlanMode` tool, you SHOULD keep the plan under 10 lines -- only outline the high-level steps.
        '');

        git = ''
          - You MUST make commits after each atomic unit of work that changes files, so that the user can backtrack the trajectory of the changes step by step.
            Ideally, each commit is the smallest possible self-contained logical unit, such that a different developer could seamlessly take over.
          - Keep commit messages as concise as possible.
        '';

        workflow = ''
          ${head} Acceptance criteria identification

          When starting a development task,
          you MUST identify the explicit acceptance criteria *before* editing any files,
          and add the corresponding check/verification step to your plan/todo list.

          After finishing the task, you MUST verify that the solution meets the acceptance criteria.
          If some criteria are NOT met, you MUST continue iterating on the problem, until ALL the acceptance criteria are met.
          The task CAN NOT be considered complete until ALL the acceptance criteria are met.

          If the user asks you to fix a failing command, successful execution of this command MUST be added as a criterion.

          Typical acceptance criteria:

          <example>
            <user>implement a new feature: ...</user>
            <acceptance_criteria>
              1. All currently passing tests remain passing.
              2. The project builds successfully.
              3. New tests are added and pass.
            </acceptance_criteria>
          </example>
          <example>
            <user>a command is failing: ...</user>
            <acceptance_criteria>
              1. All currently passing tests remain passing.
              2. The specific command that was failing now succeeds.
            </acceptance_criteria>
          </example>
          <example>
            <user>add a flake for the project</user>
            <acceptance_criteria>
              1. `nix build` succeeds.
              2. The program runs successfully using `nix run`.
            </acceptance_criteria>
          </example>
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
    opencode = mkInstructions {
      agent = "opencode";
      planningTool = "todowrite";
      subagentTool = "task";
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
