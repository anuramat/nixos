{ config, ... }:
{
  programs.git.hooks.prepare-commit-msg =
    config.lib.home.gitHook
      # bash
      ''
        COMMIT_MSG_FILE=$1
        COMMIT_SOURCE=$2

        # NOTE that COMMIT_MSG_FILE only has comments when it's invoked interactively
        # meanwhile with `commit -m` it already contains the message
        # e.g. claude always uses `commit -m`
        signature="Co-Authored-By: ${"$" + config.lib.agents.varNames.agentName}"
        if [ -v ${config.lib.agents.varNames.agentName} ]; then
        	if [ "$COMMIT_SOURCE" = "commit" ]; then
        		echo 'permission error: agents are not allowed to use `git commit` with flags `-c`, `-C`, or `--amend`'
        		exit 1
        	fi
        	if ! [ -s "$COMMIT_MSG_FILE" ]; then
        		echo 'error: empty commit message'
        		exit 1
        	fi
        	if grep -q "$signature" "$COMMIT_MSG_FILE"; then
        		echo 'assertion error: commit already contains a "Co-Authored-By" trailer'
        		exit 1
        	fi
        	printf '\n%s' "$signature" >> "$COMMIT_MSG_FILE"
        fi
      '';
}
