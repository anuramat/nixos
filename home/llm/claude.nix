{
  lib,
  hax,
  pkgs,
  ...
}:
let
  hooks = {
    Notification = [
      {
        hooks = [
          {
            command = "jq .message -r | xargs -0I{} notify-send 'Claude Code' {}";
            type = "command";
          }
        ];
        matcher = "";
      }
    ];
  };
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
  varNames = {
    rwDirs = "RW_DIRS";
    isClaude = "CLAUDE";
  };
  env = {
    ${varNames.isClaude} = 1;
  };
in
{
  home.file = {
    ".claude/CLAUDE.md".text = import ./prompt.nix { inherit lib varNames; };
    ".claude/settings.json".text = lib.generators.toJSON { } {
      includeCoAuthoredBy = false;
      inherit hooks env permissions;
    };
    # TODO make a helper that creates commands
    ".claude/commands/memchk.md".text = ''
      ---
      description: memory file update guided by direct verification
      ---

      I want you to update CLAUDE.md, since the project changed a lot.

      Go through CLAUDE.md and partition the statements/instructions into parts,
      that correspond to independent parts of the project.

      For each set of statements/instructions and corresponding part of the
      project, run a parallel agent and verify every statement/instruction, by
      looking up the relevant files and their contents:

      - Statements should correctly reflect the state of the project.
      - Instructions should be valid: for example, if instruction tells you to
        use a makefile target that was renamed/deleted/moved to a shell script --
        update it accordingly.
    '';
    ".claude/commands/render.md".text = ''
      ---
      description: fix a pandoc render issue
      ---

      I want you to figure out why this markdown file doesn't get rendered
      with my `pandoc` script. Usually, the problem is in the LaTeX code in
      the math blocks. Use the command `render input.md output.pdf`, read the
      error message, edit the file, and try to render again. Test command --
      aforementioned `render`. 

      - Do not try to debug `pandoc`, LaTeX engine itself, or the `render`
        script -- it's practically never the issue.
      - Error messages will show confusing line numbers -- they correspond to
        an intermediate representation, and thus are irrelevant in the context
        of fixing the markdown file. You can ignore the line numbers. Focus on
        the LaTeX code mentioned in the error message, and grep for it (if
        available).
    '';
    ".claude/commands/texify.md".text =
      let
        cmd = "LC_ALL=C rg '[^[:print:]]' --line-number";
      in
      ''
        ---
        description: replacement of non-ascii characters with latex in markdown files
        ---

        I want you to replace all non-ASCII characters in markdown files with
        corresponding inline math `$...$` or math blocks `$$...$$`. If you find
        something like umlauts in german names, you should replace them with
        corresponding ASCII equivalents, eg `Jäger` becomes `Jaeger`.

        Here is the list of non-ASCII characters found in the files:

        !`${cmd}`

        Do the necessary replacements, and then verify that everything was
        replaced, using this command:

        `${cmd}`
      '';
    ".claude/commands/memupd.md".text =
      let
        memfile = "CLAUDE.md";
        shortdiff_cmd = "${commit_cmd} | xargs git diff --numstat";
        commit_cmd = "git log -1 --format=%H ${memfile}";
      in
      ''
        ---
        description: memory file update guided by git history
        ---

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
        if [ -v ${varNames.isClaude} ]; then
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

      # TODO add single file mode
      text = ''
        ${varNames.rwDirs}+=(/tmp "$XDG_CONFIG_HOME/claude" "$PWD" "$HOME/.claude.json" "$HOME/.claude")

        if gitroot=$(git rev-parse --show-toplevel 2>/dev/null) && [ -d "$gitroot" ]; then
          ${varNames.rwDirs}+=("$gitroot")
        fi

        XDG_DATA_HOME=$(mktemp -d)
        XDG_STATE_HOME=$(mktemp -d)
        XDG_CACHE_HOME=$(mktemp -d)
        XDG_RUNTIME_DIR=$(mktemp -d)

        export XDG_DATA_HOME
        export XDG_STATE_HOME
        export XDG_CACHE_HOME
        export XDG_RUNTIME_DIR

        args=()
        for i in "''${${varNames.rwDirs}[@]}"; do
        	args+=(--bind)
        	args+=("$i")
          args+=("$i")
        done

        echo "RW mounted directories:"
        printf '%s\n' "''${${varNames.rwDirs}[@]}"
        export ${varNames.rwDirs}

        bwrap --ro-bind / / --dev /dev "''${args[@]}" claude --dangerously-skip-permissions "$@"
      '';
    })
  ];
}
