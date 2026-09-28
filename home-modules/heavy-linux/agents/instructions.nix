{ lib, inputs, ... }:
let
  agentHosts =
    inputs.self.hosts
    |> lib.filterAttrs (_: v: !v.deprecated && v.agent)
    |> lib.mapAttrsToList (n: v: "- `${n}` -- ${v.description}")
    |> lib.concatStringsSep "\n";

  mkInstructions =
    agent:
    let
      for = agents: lib.optionalString (lib.elem agent agents);

      sections = [
        {
          name = "general";
          body = ''
            - The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", "MAY" are to be interpreted as described in RFC 2119.
            - You MUST NOT do "band-aid" fixes -- ALWAYS fix the root cause of the problem.
            - When writing a commit message, the subject MUST be of the form `$SCOPE: $SHORT_DESCRIPTION`. Note that it's NOT `$TYPE($SCOPE): $SHORT_DESCRIPTION` as in conventional commits -- you MUST omit the type. WIP commits get an additional "WIP: " prefix.
            - Backward compatibility is not a goal, unless explicitly specified. You MUST NOT add fallbacks, shims, wrappers, aliases, or dual behavior for old codepaths.
            - If user refers to "spec" without specifying, ./SPEC.md is usually implied
            - If you change the types/semantics of existing code, you MUST rename the relevant functions/variables to reflect the changes; e.g. if variable name contains "list" but it is no longer a list, you MUST rename it to avoid confusion.
            - You MUST NOT remove existing comments, unless they're outdated. if you do, you SHOULD inform the user.
          ''
          + (for [ "claude" ] ''
            - You SHOULD use the `AskUserQuestion` tool whenever you have questions for the user -- it lets them pick options instead of typing, and consolidates scattered questions into one place. Exceptions:
              - The answer requires freeform input (names, paths, values, snippets, open-ended feedback).
              - You can't come up with 2+ genuinely distinct options.
              - Plan approval -- use `ExitPlanMode`.
          '');
        }
        {
          name = "codestyle";
          body = ''
            Background:
            The user works on a solo project and wants it to be easy to maintain.
            The biggest burden is the sheer amount of code -- every line is a potential bug, takes up space on the screen, and increases cognitive load.
            You should aim for the smallest possible amount of code that does the job.

            - You MUST write concise code that prioritizes brevity and elegance over verbosity and caution.
            - You MUST NOT implement features that are neither explicitly requested by the user nor indirectly required.
            - You MUST avoid exhaustive error handling and edge case checks.

            Exceptions:
            - Temporary files (e.g. debugging/test scripts) -- you MAY write as much code as you need in temporary files.
            - Helper functions -- you SHOULD decompose complex logic into helper functions when appropriate.
            - Tests -- coverage takes priority over brevity.
            - AI-owned code ("SLOP")
          '';
        }
        {
          name = "code-ownership";
          body = ''
            Code marked by user as "SLOP" is "AI-owned": it was "vibecoded" --
            written by an agent with little to no supervision/review from the
            user, and is thus treated by the user as a black box.

            - User will not edit it manually in the future, unless the user decides to take ownership by reviewing the code and removing the "SLOP" mark.
            - All general code style instructions are relaxed for SLOP
            - You SHOULD write comprehensive tests for SLOP -- it's a higher priority for SLOP than the rest of the codebase.
            - If an entire directory or the corresponding module is marked as SLOP, you MAY freely add/remove files in this directory
            - SLOP should be minimally coupled to the rest of the codebase -- ideally, it should have a well-defined interface and be used as a black box by the rest of the codebase.
          '';
        }
        {
          name = "workflow";
          body = ''
            ### Acceptance criteria identification

            When starting a development task, you MUST identify the explicit
            acceptance criteria *before* editing any files, and add the
            corresponding check/verification step to your plan/todo list.

            After finishing the task, you MUST verify that the solution meets the acceptance criteria.
            If some criteria are NOT met, you MUST continue iterating on the problem, until ALL the acceptance criteria are met.
            The task MUST NOT be considered complete until ALL the acceptance criteria are met.

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
        }
        {
          name = "environment";
          body = ''
            - If you need tools that are not available on the system, you SHOULD use `nix run nixpkgs#package_name -- arg1 ...`.
            - Don't run `find` and similar commands on paths like `/` or `/nix/store` -- those are huge.
            - User is running NixOS, the flake is located in `/etc/nixos`. Whenever user refers to "the NixOS configuration", this path is implied. You MAY read files in this directory for context.
            - nixpkgs search: `nh search $PACKAGE_NAME`; prefer this over `nix search`, which is slower
            - If user asks you to "notify" them about something, `tgfy` command is implied. It sends a Telegram message to the user. Usage: `echo 'text message' | tgfy file1.txt file2.png`. Attachments are optional.
          '';
        }
        {
          name = "sandbox";
          body = ''
            You are running in a sandbox.

            Some commands may not work as expected. If you suspect that a command
            is not working because of the sandbox, you MAY ask the user to run the
            command manually.

            Important: `/tmp`, `$TMPDIR`, and XDG cache/data/state home directories
            are bind mounted to tmpfs, so files created there will not persist
            after the session is finished. Most of the other paths are bind
            mounted read-only.
          '';
        }
        {
          name = "ssh";
          body = ''
            You have SSH access to the following machines as the unprivileged `agent` user:

            ${agentHosts}

            Each host has the same packages as the user, and its home directory persists
            across sessions. Start long runs with
            `systemd-run --user --unit=SHORT_DESCRIPTIVE_NAME` -- they keep
            running after you disconnect, and the user can see them by name.
            Anything else you start (`cmd &`, `nohup`, `setsid`, tmux) is killed
            when the ssh command returns.
          '';
        }
      ];
    in
    [ "# Global instructions\n" ] ++ map (s: "## ${s.name}\n\n${s.body}") sections
    |> lib.concatStringsSep "\n";
in
{
  lib.agents.instructions = lib.genAttrs [ "claude" "codex" "omp" ] mkInstructions;
}
