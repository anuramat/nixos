# Instructions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be interpreted as
described in RFC 2119.

## Projects and directories

### NixOS

- User is running NixOS, and the corresponding repository is located in
  `/etc/nixos`
- It contains configuration of all parts of the system, thus whenever user
  mentions software installation or configuration, this flake is implied.

### Other repositories

- Other repositories are located in `$(ghq root)`.
- They can be listed with bash command `ghq list -p`
- Whenever project documentation or code could provide useful context, you MUST
  check the list of of locally available repositories first, before searching
  online or trying to guess.

## Permissions

You typically are running in a `bubblewrap` sandbox. Most of the paths are
mounted in read-only mode, with a few exceptions:

```txt
~/.claude.json
~/.claude/
$PWD
/tmp/
$XDG_CACHE_HOME
```

Commands that modify anything not on this list will usually fail.

## Protocol

You MUST integrate this two-stage protocol into your workflow:

### Stage 1: Test command identification

Before starting ANY task you MUST explicitly identify a "test command". Examples
of typical cases:

- if there are any tests: you MUST run tests
- nix flake: you MUST run `nix build`; `nix run` -- if applicable
- minor proof-of-concept script -- you MUST demonstrate that it works

When working on a big feature, you MUST write tests first (test-driven
development).

### Stage 2: Dev-test loop

You MUST repeat the "dev" and "test" steps until you succeed:

1. Dev: implement the solution, a part of the solution, or fix a problem. You
   MUST NOT disable problematic features.
2. Test: run the "testing command".
3. If the task is not completed, or the "test command" fails, go to step 1.

Only consider the task complete, when the "test command" succeeds.

## Code style

Background: the user can't trust AI generated code, thus he has to always review
it thorouhgly.

You MUST write concise, minimalist, self-documenting code that prioritizes
brevity and elegance over verbosity and caution, "move fast and break things"
style. This will allow the user to review the changes in the smallest possible
amount of time, greatly increasing his productivity.

- Prefer:
  - Compact constructs: oneliners, lambdas, pipes, list comprehensions
  - Functional style
- Avoid:
  - Bloat, boilerplate, verbosity
  - Exhaustive error handling
  - Unnecessary edge case checks
  - Excessive comments
  - Bloated code formatting with a lot of newlines
- Arcane but effective solutions are welcome

With complex multi-step problems you SHOULD prefer a two stage approach: write
verbose code, then refactor it to meet the code style guidelines.

## Git

- You MUST make commits after each successful step, so that the user can
  backtrack the trajectory of the changes step by step.
- Keep commit messages as concise as possible.

## Memory

- You MUST NOT edit global memory or `AGENTS.md` files, as they contain user
  instructions.
- You MUST NOT edit import lines (`@filepath`) in memory files
- You are responsible for keeping project memory consistent with the state of
  the project
  - If you make significant changes or otherwise notice inconsistencies in the
    project memory, you MUST immediately edit it such that it reflects the
    current state of the project.
  - You MUST NOT remove correct statements from the project memory.
  - After editing memory file, you MUST make a git commit with *all* changes
    (`git add .`) in the repository checked in.
  - You MUST NOT blindly trust project memory, as it gets outdated quick -- the
    source of truth is the code.

## Nix

- When creating a new file in a nix flake repository, you MUST run `git add .`,
  otherwise it is ignored by the flake
