{
  config,
  lib,
  inputs,
  osConfig ? null,
  ...
}:
let
  inherit (inputs.self.consts.agent) sharedDir;
  inherit (config.lib.agents) userSharedDir;
  # unknown under standalone Home Manager
  currentHost = lib.optionalString (osConfig != null) (
    let
      inherit (osConfig.networking) hostName;
    in
    ''
      You are running on `${hostName}` (${inputs.self.hosts.${hostName}.description}).

    ''
  );

  mkInstructions =
    agent:
    let
      for = agents: lib.optionalString (lib.elem agent agents);

      sections = [
        {
          name = "General";
          body = ''
            The key words "MUST", "MUST NOT", "SHOULD", "SHOULD NOT", "MAY" are
            to be interpreted as described in RFC 2119.

            You MUST NOT do "band-aid" fixes -- ALWAYS fix the root cause of the
            problem.

            When writing a commit message, the subject MUST be of the form
            `$SCOPE: $SHORT_DESCRIPTION`. Note that it's NOT `$TYPE($SCOPE):
            $SHORT_DESCRIPTION` as in conventional commits -- you MUST omit the
            type. WIP commits get an additional "WIP: " prefix.

            Unless the user asks for a new branch, you MUST commit on the
            current branch, even if it's the default one.

            Backward compatibility is not a goal, unless explicitly specified.
            You MUST NOT add fallbacks, shims, wrappers, aliases, or dual
            behavior for old codepaths.

            If user refers to "spec" without specifying, ./SPEC.md is usually
            implied; ./SPEC.md is typically a temporary document that is dropped
            or consolidated into project documentation once the spec is
            implemented, so it shouldn't be mentioned in code, comments, or
            commit messages.

            If you change the types/semantics of existing code, you MUST rename
            the relevant functions/variables to reflect the changes; e.g. if
            variable name contains "list" but it is no longer a list, you MUST
            rename it to avoid confusion.

            You MUST NOT remove existing comments, unless they're outdated. if
            you do, you SHOULD inform the user.

            You MUST use plain ASCII whenever possible, e.g. `--` instead of an
            em dash, `->` instead of an arrow. In markup, you MUST use the
            markup's own syntax instead of Unicode symbols: `\lambda` in LaTeX
            and Markdown math, `lambda` in Typst math.
          ''
          + (for [ "claude" ] ''
            You SHOULD use the `AskUserQuestion` tool whenever you have
            questions for the user -- it lets them pick options instead of
            typing, and consolidates scattered questions into one place.
            Exceptions:
            - The answer requires freeform input (names, paths, values, snippets, open-ended feedback).
            - You can't come up with 2+ genuinely distinct options.
            - Plan approval -- use `ExitPlanMode`.
          '');
        }
        {
          name = "Code style";
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
          name = "Code ownership";
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
          name = "Workflow";
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
          name = "Environment";
          body = currentHost + ''
            User is running NixOS, configured by the flake in `/etc/nixos`;
            whenever user refers to "the NixOS configuration", this path is
            implied. Everything is defined there, including your own
            environment: the sandbox, your SSH access, and the `hostrun` and
            `uc3ctl` relays (`home-modules/heavy-linux/agents/` and
            `nixos-modules/base/agent.nix`). You MAY read it for context; if you
            hit a limitation of your environment, you SHOULD read the relevant
            code to understand exactly what is allowed and how to work around
            it, before asking the user.

            - If you need tools that are not available on the system, you SHOULD use `nix run nixpkgs#package_name -- arg1 ...`.
            - Don't run `find` and similar commands on paths like `/` or `/nix/store` -- those are huge.
            - nixpkgs search: `nh search $PACKAGE_NAME`; prefer this over `nix search`, which is slower
            - If user asks you to "notify" them about something, `notify` command is implied. It is for alerts that need the user's attention now: it sends a notification to whichever machine the user is at, or to their phone. Usage: `echo 'text message' | notify`; the message must be under 4096 bytes, with no attachments -- use `tgfy` for files.
            - If user asks you to send something over Telegram, `tgfy` command is implied; it is also for anything the user wants to keep or receive in Telegram, e.g. files or reports. Usage: `echo 'text message' | tgfy file1.txt file2.png`. Attachments are optional.
          '';
        }
        {
          name = "Sandbox";
          body = ''
            You are running in a sandbox. Some commands may not work as
            expected.

            Important: `/tmp`, `$TMPDIR`, and XDG cache/data/state home directories
            are bind mounted to tmpfs, so files created there will not persist
            after the session is finished. The working directory and its git
            worktree are writable; most of the other paths are bind mounted
            read-only.

            The user gives you ad-hoc read-only access to files by putting
            them in `${userSharedDir}`; if the user mentions a shared file
            without a path, look there, not in `${sharedDir}`.
          '';
        }
        {
          name = "Environment feedback";
          body = ''
            Your environment is defined in `/etc/nixos`.

            When it doesn't match your instructions -- an instruction is stale,
            wrong, or ambiguous enough that you had to guess; a documented tool is
            missing or behaves differently; a sandbox limitation needs a
            workaround -- you SHOULD report it once you've figured out what's
            actually true, so that the user can fix it later:

            ```sh
            agent-feedback <<'EOF'
            Instructions say X, but actually Y (/etc/nixos/path/to/file.nix:42);
            the "Section" section should say Y.
            EOF
            ```

            Say what you expected, what turned out to be true, how you found out,
            and what should change. The time, host, current directory, and
            configuration revision are recorded automatically. This is only for
            problems with your environment, not with the project you're working
            on, and it doesn't replace telling the user what matters for the
            current task.
          '';
        }
      ];
    in
    [ "# Global instructions\n" ] ++ map (s: "## ${s.name}\n\n${s.body}") sections
    |> lib.concatStringsSep "\n";
in
{
  lib.agents.instructions = lib.genAttrs [ "claude" "codex" ] mkInstructions;
}
