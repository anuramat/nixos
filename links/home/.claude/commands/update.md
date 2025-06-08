# memory update

this is a command that lets the user update the CLAUDE.md memory file when the
project accumulates significant changes. to do that, claude takes a
progressively more detailed look at the git history since the last change in
CLAUDE.md, and updates it accordingly.

## step 1

get the short summary:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --shortstat
```

if there are no potentially significant changes, stop and tell the user that
there were no significant changes. otherwise, proceed to step 2:

## step 2

get a more detailed per-file summary:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --numstat
```

if there are no potentially significant changes, stop and tell the user that
there were no significant changes. otherwise, proceed to step 3:

## step 3

get the full diff:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --
```

if necessary, read the files that were changed, or even other files. then
proceed to step 4:

## step 4

read the CLAUDE.md and update it with the changes you analyzed.

commit the changes with the message `docs(CLAUDE.md): update memory`
