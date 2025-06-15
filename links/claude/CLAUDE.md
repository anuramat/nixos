# Instructions

- You MUST NOT modify anything outside of the current directory other than the
  global memory file; for all the other files ask the user instead
- After finishing the task you were assigned, you MUST check that the code
  compiles and runs, and that the requested changes are implemented correctly.
  - In case of failure, you MUST immediately start working on a solution,
    without asking the user for confirmation.

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
memory for future reference:

- Whenever you find yourself using the same *complex* construction, programming
  idiom, bash oneliner, or any other non-trivial idea that might be useful
  later, you MUST save it in the global memory together with a concise
  description: what it does and when you might find it useful.

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

## Code

- Don't write too much code -- try to be as concise as possible.
- When making architecture decisions, go for minimalism.
- Only add comments where descriptive names are not enough.

## Nix

- When creating a new file in a nix flake repository, you MUST run `git add .`,
  otherwise it is ignored by the flake

# Global memory
