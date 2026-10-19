{ lib, inputs, ... }:
let
  inherit (inputs.self.consts.agent) username sharedDir;
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
          body = ''
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
            - If user asks you to "notify" them about something, `tgfy` command is implied. It sends a Telegram message to the user. Usage: `echo 'text message' | tgfy file1.txt file2.png`. Attachments are optional.
          '';
        }
        {
          name = "Sandbox";
          body = ''
            You are running in a sandbox.

            Some commands may not work as expected. If a command can't work in
            the sandbox (e.g. it needs the user's SSH keys or user services, or
            writes outside the bound paths), you MAY ask the user to approve
            running it outside the sandbox with `hostrun -d DESC -c CMD`, where
            CMD is a single argument, run with `bash -c`, or `hostrun -d DESC
            -f FILE`, which runs FILE's content the same way; FILE is read
            inside the sandbox, so it can be in your scratchpad, or
            `/dev/stdin` with a heredoc. DESC is a short one-line description
            of what the command does, e.g. `list the files in X's wine prefix`:
            the user's notification shows only DESC, and the review shows it
            next to the command. hostrun blocks until the user answers, then
            runs the command as the user on this host, in the current
            directory, or, with `-h HOST`, over ssh as the user on HOST, in the
            user's home there (unlike your own `ssh HOST`, which logs in as
            `agent`). stdout, stderr and the exit status are passed through,
            stdin is `/dev/null`, and exit status 77 means the user denied it.
            Paths that only exist in the sandbox, such as anything under
            `/tmp`, don't exist outside it.
          ''
          + (for [ "claude" ] ''
            Approval can take minutes: run `hostrun` with Bash `run_in_background`.
          '')
          + ''

            The user reviews every `hostrun` command (with `-f`, the file's
            content) before approving it, and sees nothing else, so you MUST
            NOT make it run files you wrote (e.g. `hostrun -c 'bash x.sh'`),
            and you SHOULD write it for readability: e.g. use `-h HOST` instead
            of `ssh HOST` in the command, and organize long commands as `-f`
            scripts with comments and descriptive names instead of huge
            one-liners or layers of quoting.

            Important: `/tmp`, `$TMPDIR`, and XDG cache/data/state home directories
            are bind mounted to tmpfs, so files created there will not persist
            after the session is finished. Most of the other paths are bind
            mounted read-only.

            A process can only trace its own descendants (`kernel.yama.ptrace_scope=1`,
            in and outside the sandbox), so attaching to a running process
            (`py-spy dump --pid`, `gdb -p`, `strace -p`) fails: start it under
            the tool instead, e.g. `py-spy record -- python ...`.
          '';
        }
        {
          name = "Environment feedback";
          body = ''
            Your environment is defined in `/etc/nixos`, which you can't edit.
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
        {
          name = "SSH and long-running jobs";
          body = ''
            You have SSH access to the following machines as the unprivileged `${username}` user:

            ${agentHosts}

            Its home directory persists across sessions. Anything you start over
            ssh is killed when the ssh command returns.

            Anything that should outlive your session, or runs longer than ~10
            minutes, MUST be run as a job:

            - `job run HOST:NAME -d DESC [-e WHEN] -- CMD...` runs CMD as
              `${username}` on HOST, in `D=${sharedDir}/jobs/NAME` on HOST; output
              goes to `D/log`. NAME is `[a-z0-9-]+` and can't be reused.
            - DESC and the ETA are shown to the user next to the job. DESC is
              required: about 40 characters, what is run on what, e.g.
              `smoke test of A on B` or `full training run of C with D`.
            - `-e WHEN` sets the ETA, in `date -d` syntax: `'90 min'`, `'2 hours'`,
              `'1 hour 30 min'`. You SHOULD always set it, estimated from a smoke
              test's throughput times the total work, or a previous run's duration.
            - `job eta HOST:NAME WHEN` updates the ETA; like `-e`, WHEN is the time
              left from now, not the total duration since the job started. When
              the job's progress shows that the estimate is off by more than ~20%,
              you SHOULD update it.
            - `job wait [-f] HOST:NAME` blocks until the job ends and prints
              `job NAME: RESULT`. Exit 0 = success, 1 = failed or cancelled,
              2 = no such job, 3 = lost (e.g. reboot), 4 = ssh failed (retry).
              `-f` also streams new log lines.
            - `job stop HOST:NAME` cancels it.

            `${username}` can't read the user's home, so you MUST stage everything the
            job needs in D first. The sandbox can read `${sharedDir}` but
            not write it: write to D only through ssh, using `HOST:` paths even
            for this host (`$HOSTNAME`). Example, from the root of a flake repo:

            ```sh
            H=$HOSTNAME # or another host from the list above
            D=${sharedDir}/jobs/NAME
            # just the flake files, so that nix doesn't copy the repo into the store
            rsync -t --mkpath flake.nix flake.lock "$H:$D/flake/"
            git ls-files -z -co --exclude-standard |
              rsync -rlpt --from0 --files-from=- --mkpath ./ "$H:$D/src/"
            job run "$H:NAME" -d 'full training run of C with D' -e '2 hours' -- \
              sh -c "cd src && nix develop path:$D/flake -c python train.py"
            ```

            - If the flake reads other repo files (e.g. `src = ./.`), copy those to `D/flake` too.
            - Big data (datasets, caches) SHOULD live in `${sharedDir}/data/PROJECT` on the host, symlinked into D: `ssh $H ln -s ${sharedDir}/data/PROJECT/cache $D/src/cache`.
            - Results: read D directly on this host; on another host, use `ssh $H tail $D/log` or `rsync -rlpt "$H:$D/src/out/" out/`.
            - Record `HOST:NAME` wherever the run is documented, so a later session can re-attach with `job wait`.
          ''
          + (for [ "claude" ] ''
            - Right after launching, run `job wait HOST:NAME` with Bash `run_in_background` -- you get notified when it ends. For progress, run `job wait -f HOST:NAME | grep --line-buffered -E 'PATTERN|^job '` in the Monitor tool, filtered to lines you'd act on, e.g. errors and progress (to update the ETA). You MUST NOT poll with foreground `sleep`.
          '');
        }
      ];
    in
    [ "# Global instructions\n" ] ++ map (s: "## ${s.name}\n\n${s.body}") sections
    |> lib.concatStringsSep "\n";
in
{
  lib.agents.instructions = lib.genAttrs [ "claude" "codex" "omp" ] mkInstructions;
}
