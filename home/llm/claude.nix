{
  lib,
  hax,
  pkgs,
  ...
}:
let
  prompt = # markdown
    ''
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

      You typically are running in a `bubblewrap` sandbox. Most of the paths outside
      of the `$PWD` are mounted in read-only mode, so some commands might fail.

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
        - Language specific preferences:
          - Nix: `let ... in`, helper lambdas, `inherit`, `with`
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

      - You MUST NOT edit `AGENTS.md` files, as they contain user
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

      ## Misc

      - If you need tools that are not available on the system initially, you can use
        `nix run nixpkgs#packagename -- arg1 arg2 ...`. You can use NixOS MCP server
        to find the required package.
    '';
  settings = lib.generators.toJSON { } {
    env = { };
    includeCoAuthoredBy = false;
    permissions = {
      allow = [
        "Bash(git status:*)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "Bash(git commit:*)"
        "Bash(ls:*)"
        "Bash(find:*)"
        "Bash(fd:*)"
        "Bash(grep:*)"
        "Bash(rg:*)"
        "Bash(nix flake check:*)"
        "Bash(devenv test:*)"
        "WebFetch"
        "WebSearch"
        "mcp__nixos"
      ];
      deny = [ ];
    };
  };
in
{
  home.file = {
    ".claude/CLAUDE.md".text = prompt;
    ".claude/settings.json".text = settings;
    ".claude/commands/memcheck.md".text =
      let
        memfile = "CLAUDE.md";
        shortdiff_cmd = "${commit_cmd} | xargs git diff --numstat";
        commit_cmd = "git log -1 --format=%H ${memfile}";
      in
      ''
        ---
        description: memory file update guided by git history
        ---

        # Project memory update

        I want you to check if the project memory in ${memfile} is significantly
        outdated, and if so -- update it.

        Last commit where the memory was updated is:

        !`${commit_cmd}`

        and the corresponding diff summary is:

        !`${shortdiff_cmd}`

        In case there are significant changes -- ones that either make information in
        ${memfile} invalid, or are important enough to warrant new entries in the
        file -- explore the necessary files, and edit ${memfile}.

        If you make any changes to the memory file, commit the changes with the
        message:

        ```gitcommit
        docs(${memfile}): update

        <short_summary>
        ```

        where `<short_summary>` is a short description of the changes in the
        project that are now reflected in the memory file.
      '';
  };
  programs.git.hooks.prepare-commit-msg =
    hax.common.gitHook pkgs
      # bash
      ''
        COMMIT_MSG_FILE=$1
        COMMIT_SOURCE=$2

        # NOTE that COMMIT_MSG_FILE only has comments when it's invoked interactively
        # meanwhile with `commit -m` it already contains the message
        # claude always uses `commit -m`
        signature="Co-Authored-By: Claude <noreply@anthropic.com>"
        if [ -v CLAUDE ]; then
        	if [ "$COMMIT_SOURCE" = "commit" ]; then
        		echo 'permission error: `claude` is not allowed to use `git commit` with flags `-c`, `-C`, or `--amend`'
        		exit 1
        	fi
        	if ! [ -s "$COMMIT_MSG_FILE" ]; then
        		echo 'error: empty commit message'
        		exit 1
        	fi
        	if grep -q "$signature" "$COMMIT_MSG_FILE"; then
        		echo 'assertion error: commit already contains "Co-Authored-By: Claude" trailer'
        		exit 1
        	fi
        	printf '\n%s' "$signature" >> "$COMMIT_MSG_FILE"
        fi
      '';
  home.packages = [
    (pkgs.writeShellApplication {
      name = "cld";
      runtimeInputs = with pkgs; [
        claude-code
        bubblewrap
      ];
      text = ''
        export CLAUDE=true # this is used in git hooks

        rw_dirs+=(/tmp "$XDG_CONFIG_HOME/claude" "$PWD" "$HOME/.claude.json" "$HOME/.claude")

        export XDG_DATA_HOME=$(mktemp -d)
        export XDG_STATE_HOME=$(mktemp -d)
        export XDG_CACHE_HOME=$(mktemp -d)
        export XDG_RUNTIME_DIR=$(mktemp -d)

        args=()
        for i in "''${rw_dirs[@]}"; do
        	args+=(--bind)
        	args+=("$i")
          args+=("$i")
        done

        bwrap --ro-bind / / --dev /dev "''${args[@]}" claude --dangerously-skip-permissions "$@"
      '';
    })
  ];
}
