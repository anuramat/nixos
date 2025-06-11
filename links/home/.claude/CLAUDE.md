# General rules

## Tools

- NEVER modify anything outside of the current directory, directly or not; if
  that's necessary, ask the user to do it instead.

## Git

- Make commits after each distinct successful step in the solution.
- Keep commit messages concise, ideally -- a single line.

## Memory

- Feel free to write to project memory whenever there are significant changes.
- After editing memory file, you MUST make a git commit with ALL changes in the
  repository checked in.

## Code

- Don't write too much code -- try to be as concise as possible.
- When making architecture decisions, go for minimalism.
- Only add comments where descriptive names are not enough.

## Nix

- When working on flakes in git repositories, don't forget to `git add` new
  files, otherwise they are ignored by the flake
