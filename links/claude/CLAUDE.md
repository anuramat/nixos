# Instructions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be interpreted as
described in RFC 2119.

## Projects and directories

### NixOS

User is running NixOS, and the corresponding repository is located in
`/etc/nixos`. It contains configuration of all parts of the system, thus
whenever user mentions software installation or configuration, this flake is
implied.

### Misc

Other repositories are located in `$(ghq root)`. They can be listed with bash
command `ghq list -p`. Whenever project documentation or code could provide
useful context, you MUST check the list of of locally available repositories
first, before searching online or trying to guess.

### Permissions

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

## Workflow

- After finishing the task you were assigned, you MUST check that the code
  compiles and runs, and that the requested changes are implemented correctly.
  - In case of failure, you MUST immediately start working on a solution,
    without asking the user for confirmation.
  - When working on big features, you SHOULD write tests -- either in the
    beginning (in the test-drived development paradigm), or after finishing the
    task. You MUST run them every time you think you are finished.

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

### Git

- You MUST make commits after each successful step, so that the user can
  backtrack the trajectory of the changes step by step.
- Keep commit messages as concise as possible.

## Memory

- You are responsible for memory files `CLAUDE.md`
- You MUST NOT edit `AGENTS.md` files, as they are only to be edited by the
  user.
- You MUST NOT edit import lines (`@filepath`) in memory files

### Global memory

You are responsible for storing useful facts, ideas, and snippets in global
memory for future reference: whenever you find yourself using the same
construction, programming idiom, bash oneliner, online resource, or any other
non-trivial idea that might be useful later, you MUST save it in the global
memory together with a concise description: what it does and when you might find
it useful.

### Project memory

You are responsible for keeping project memory consistent with the state of the
project:

- If you make significant changes or otherwise notice inconsistencies in the
  project memory, you MUST immediately edit it such that it reflects the current
  state of the project.
  - You MUST NOT remove correct statements from the project memory.
  - After editing memory file, you MUST make a git commit with *all* changes in
    the repository checked in (`git add .`, then `git commit`).
- You MUST NOT blindly trust project memory, as it gets outdated quick. The
  source of truth is the code. Use the project memory as the starting point.

## Nix

- When creating a new file in a nix flake repository, you MUST run `git add .`,
  otherwise it is ignored by the flake

# Global memory
