{ lib, inputs, ... }:
let
  inherit (inputs.self.consts.agent) username sharedDir;
  agentHosts =
    inputs.self.hosts
    |> lib.filterAttrs (_: v: v.agent)
    |> lib.mapAttrsToList (n: v: "- `${n}` -- ${v.description}")
    |> lib.concatStringsSep "\n";

  mkSkills =
    agent:
    let
      for = agents: lib.optionalString (lib.elem agent agents);
    in
    {
      explain-diff = {
        description = "explain a diff in a human-friendly way, so that the user can easily review it";
        text = ''
          Help me review this diff by providing a review guide:

          I will open it side by side with code, go through the review
          instructions top to bottom, and read mentioned files.

          Review instructions must be structured as a list of bullet points: each
          point must mention a few files and a short explanation of the changes.

          Order should be such that I can comfortably learn what changed in this
          diff, and incrementally build a mental model of the changes.


          After the bullet points, provide a concise summary of the changes.

          You must omit the changes to tests from the review guide. If there are
          files that only had tests changed/added/removed, you must list them in a
          separate list after the summary -- it should be a bullet point list of
          file names, with no explanations.
        '';
      };
      iterate-spec = {
        description = "refine feature specification/implementation plan/design document/SPEC.md/PLAN.md";
        text = ''
          Specification describes a feature that was not yet implemented. Your
          task is to review the specification and report to user. Do not edit the
          files.

          Identify and report:

          - ambiguities and contradictions in described feature behaviour
          - missing important edge cases
          - implicit contradictions with existing code behaviour or assumptions
          - behaviour that appears difficult to implement without major refactoring
          - inconsistent naming or terminology
          - anything else that is likely to cause problems in the future: bugs, maintainability issues, etc.

          Properties of a good spec:

          - internal consistency: spec should not contradict itself
          - consistency with existing code: spec should not make incorrect assumptions about existing behaviour
          - completeness of decription/deterministic result: there should be one obvious way to implement the spec
          - quality of the end result: resulting implementation should be maintainable and correct
        '';
      };
      rust = {
        description = "conventions for writing, testing and building Rust code; use whenever editing or creating a Rust project";
        files.template = inputs.self.templates.rust.path;
        text = ''
          ## code

          - in binary crates, instead of `pub(crate)`, you MUST use `pub`: nothing
            is exported from a binary, so the two are equivalent (`dead_code` still
            fires on unused `pub` items), and `(crate)` is just noise

          ## crates

          You SHOULD prefer these general-purpose crates over hand-written
          equivalents:

          - errors: `anyhow` for propagating errors with `.context()`; `thiserror`
            only for error enums that callers match on
          - derives: `derive_more` (`From`, `Display`, `Deref`, `Constructor`,
            ...), `derive-getters`, `smart-default` (`#[default = ...]` on fields),
            `strum` (enum <-> string, iteration over variants)
          - delegation and trait objects: `ambassador` (delegate trait impls to a
            field/variant), `dyn-clone` (`Clone` for `Box<dyn Trait>`), `typetag`
            (serde for trait objects), `inventory` (distributed static
            registration)
          - serde: `serde`, `serde_json`, `toml`, `serde_plain` (enum <-> plain
            string via serde), `schemars` (JSON schema from types)
          - async: `tokio`, `futures`, `tokio-stream`, `async-trait` (only for
            `dyn`-compatible async traits)
          - tests: `insta`, `similar-asserts` (see `## tests`)

          ## tests

          - you SHOULD try using snapshot tests using `insta` instead of manual assertions
            - if some parts of the snapshot are unstable (e.g. timestamps), use redactions
            - prefer `assert_yaml_snapshot!` over `assert_json_snapshot!`, unless you're specifically testing serialization to JSON
            - prefer inline snapshots over snapshot files
          - if snapshots are a bad fit, instead of the built-in `assert_eq!()` macro you MUST
            use `similar_asserts::assert_eq!()`; when possible, you MUST compare the
            entire struct at once, instead of checking field by field
          - test-only files MUST start with an inner `#![cfg(test)]`; the `mod`
            declaration in the parent stays unconditional
          - a normal file MUST contain at most one `#[cfg(test)]` item: a `mod tests`
            block at the end of the file
            - exception: test-only enum variants and their match arms are gated in place

          ## lints

          - the baseline is strict: most clippy groups, including `pedantic` and
            `nursery`, are enabled (groups need `priority = -1` so that individual
            lints can override them); lints that don't fit the project are
            allowed individually in `Cargo.toml`
          - the baseline is in `template/Cargo.toml`
          - you MUST fix warnings instead of silencing them; if a lint is wrong
            for the whole project, you SHOULD propose allowing it in `Cargo.toml`
            instead of adding local `#[allow]`s

          ## build

          - when building/testing, you MUST use `cargo ...` directly; if it's not
            available and the project has a flake, you MUST fall back to
            `nix develop -c cargo ...`

          ## new projects

          When creating a new Rust project, you SHOULD start from `template/` in
          this skill's directory: copy it (the files are read-only, so `chmod -R
          u+w` the copy), rename the package in `Cargo.toml`, and run `cargo
          generate-lockfile`. It contains:

          - `flake.nix`: crane build with dependencies cached separately, fenix
            stable toolchain, dev shell with `cargo-insta`, treefmt (`nix fmt`)
            run as a pre-commit hook
          - `Cargo.toml` and `clippy.toml` with the lint baseline, plus the test
            dev-dependencies
        '';
      };
      hostrun = {
        description = "run a command outside the sandbox, as the user or as root, on this or another host, after the user approves it; use when a command can't work in the sandbox, e.g. it needs the user's SSH keys or user services, or writes outside the bound paths";
        text = ''
          If a command can't work in the sandbox (e.g. it needs the user's SSH
          keys or user services, or writes outside the bound paths), you MAY
          ask the user to approve running it outside the sandbox with `hostrun
          -d DESC [-r] -c CMD`, where CMD is a single argument, run with `bash
          -c`, or `hostrun -d DESC -f FILE`, which runs FILE's content the same
          way; FILE is read inside the sandbox, so it can be in your
          scratchpad, or `/dev/stdin` with a heredoc. DESC is a short one-line
          description of what the command does, e.g. `list the files in X's
          wine prefix`: the user's notification shows only DESC, and the review
          shows it next to the command. hostrun blocks until the user answers,
          then runs the command as the user on this host, in the current
          directory, or, with `-h HOST`, over ssh as the user on HOST, in the
          user's home there (unlike your own `ssh HOST`, which logs in as
          `agent`); with `-r`, as root, through sudo, which the user
          authenticates in the review, so don't use `sudo` in CMD itself.
          stdout, stderr and the exit status are passed through, stdin is
          `/dev/null`, and exit status 77 means the user denied it. Paths that
          only exist in the sandbox, such as anything under `/tmp`, don't exist
          outside it.
        ''
        + (for [ "claude" ] ''
          Approval can take minutes: run `hostrun` with Bash `run_in_background`.
        '')
        + ''

          The user reviews every `hostrun` command (with `-f`, the file's
          content) before approving it, and sees nothing else, so you MUST NOT
          make it run files you wrote (e.g. `hostrun -c 'bash x.sh'`), and you
          SHOULD write it for readability: e.g. use `-h HOST` instead of `ssh
          HOST` in the command, and organize long commands as `-f` scripts with
          comments and descriptive names instead of huge one-liners or layers
          of quoting.
        '';
      };
      jobs = {
        description = "SSH access to the user's machines, and long-running jobs on them; read before using ssh, and before running anything that takes longer than ~10 minutes or should outlive your session";
        text = ''
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
      };
      profiling = {
        description = "sandbox limits on debuggers, tracers and profilers; read before attaching to a process (py-spy, gdb, strace) or recording call graphs with perf";
        text = ''
          A process can only trace its own descendants (`kernel.yama.ptrace_scope=1`,
          in and outside the sandbox), so attaching to a running process
          (`py-spy dump --pid`, `gdb -p`, `strace -p`) fails: start it under
          the tool instead, e.g. `py-spy record -- python ...`.

          Kernel callchains need `kernel.perf_event_paranoid` <= 1 (it's 2,
          in and outside the sandbox), so `perf record -g` and
          `--call-graph dwarf` fail: add `--user-callchains`.
        '';
      };
    };
in
{
  lib.agents.skills = lib.genAttrs [ "claude" "codex" ] mkSkills;
}
