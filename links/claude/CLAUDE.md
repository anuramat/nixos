# Instructions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to be interpreted as
described in RFC 2119.

## Projects and directories

- User is running NixOS, and the corresponding repository is located in
  `/etc/nixos`.
- Paths to other repositories can be listed with bash command `ghq list -p`.
- Whenever user mentions installing or configuring software (e.g. Neovim), you
  SHOULD read the contents of aforementioned directories to retrieve the
  necessary context.

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

## Workflow

After finishing the task you were assigned, you MUST check that the code
compiles and runs, and that the requested changes are implemented correctly.

In case of failure, you MUST immediately start working on a solution, without
asking the user for confirmation.

## Git

- You MUST make commits after each successful step.
- Keep commit messages as concise as possible, ideally -- a single line.

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

## Code guidelines

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

## Nix

- When creating a new file in a nix flake repository, you MUST run `git add .`,
  otherwise it is ignored by the flake

# Global memory
