{
  lib,
  hax,
  pkgs,
  ...
}:
let
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
    ".claude/CLAUDE.md".source = ./prompt.md;
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
        # this is used in git hooks
        CLAUDE=true
        export CLAUDE

        rw_dirs+=(/tmp "$XDG_CONFIG_HOME/claude" "$PWD" "$HOME/.claude.json" "$HOME/.claude")

        XDG_DATA_HOME=$(mktemp -d)
        XDG_STATE_HOME=$(mktemp -d)
        XDG_CACHE_HOME=$(mktemp -d)
        XDG_RUNTIME_DIR=$(mktemp -d)

        export XDG_DATA_HOME
        export XDG_STATE_HOME
        export XDG_CACHE_HOME
        export XDG_RUNTIME_DIR

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
