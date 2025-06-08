# Memory update

Update memory in ./CLAUDE.md if the project accumulated significant changes.
Follow these steps:

## Step 1

Get the short summary:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --shortstat
```

If there are no potentially significant changes, stop and tell the user that
there were no significant changes. otherwise, proceed to step 2:

## Step 2

let a more detailed per-file summary:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --numstat
```

If there are no potentially significant changes, stop and tell the user that
there were no significant changes. otherwise, proceed to step 3:

## Step 3

get the full diff:

```bash
git diff $(git log -1 --format=%H CLAUDE.md --
```

If necessary, read the files that were changed, or even other files. then
proceed to step 4:

## Step 4

Read the CLAUDE.md and update it with the changes you analyzed, then commit the
changes with the message

```gitcommit
docs(CLAUDE.md): update memory

<short_summary>
```

where `<short_summary>` should be a short description of the changes in the
project since the last memory update.
