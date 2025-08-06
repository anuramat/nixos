#!/usr/bin/env bash

set -e

SESSION_PREFIX='diriger'
INIT_SLEEP='5'

# defaults
dry_run=false
feature=""
prompt=""
root=$PWD
commands=()
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/diriger"
worktree_root="${XDG_DATA_HOME:-$HOME/.local/share}/diriger"
mkdir -p "$worktree_root"

argparse() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			-n)
				dry_run=true
				shift
				;;
			-f)
				feature="$2"
				shift 2
				;;
			-p)
				prompt="$2"
				shift 2
				;;
			-r)
				root="$2"
				shift 2
				;;
			-a)
				commands+=("$2")
				shift 2
				;;
			*)
				echo "Unknown option: $1"
				exit 1
				;;
		esac
	done

	if [[ ${#commands[@]} -eq 0 ]]; then
		[[ ! -f $config_file ]] && {
			echo "Config file $config_file not found"
			exit 1
		}
		mapfile -t commands <"$config_file"
	fi
}

# dry run wrapper
run() {
	if "$dry_run"; then
		printf '$ '
		# XXX eats the quotes, might be confusing...
		eval "printf '%s ' $*"
		echo
	else
		eval "$*"
	fi
}

launch() {
	[[ -z $feature ]] && feature="$(gum input --header='Feature:')"
	[[ -z $prompt ]] && prompt="$(gum write --header="Prompt ($feature):")"

	# launch the tmux session
	projname=$(basename "$root")
	session_name="$SESSION_PREFIX-$projname-$feature-$(uuidgen)"
	# TODO add project and feature to the session name
	echo "Session: $session_name"
	run 'tmux new -s "$session_name" -c "$root" -d'

	i=0
	for cmd in "${commands[@]}"; do
		((++i))
		agent=$(cut -d ' ' -f 1 <<<"$cmd")

		echo "Launching $cmd"

		treename="$projname-$feature-$agent-$i"
		# shellcheck disable=SC2034
		# used in `eval` inside `run`
		treepath="$(realpath "$worktree_root/$treename")"
		run 'git worktree add -b "$feature-$agent-$i" "$treepath"'

		# append the prompt
		unknown_agent=false
		ready_msg=
		if [[ -n $prompt ]]; then
			case "$agent" in
				gmn) cmd+=" -i '$prompt'" ;;
				ocd) cmd+=" -p '$prompt'" ;;
				cld) cmd+=" ' $prompt'" ;;
				crs) ready_msg="Ready?" ;;
				*) unknown_agent=true ;;
			esac
		fi

		# start the agent
		pane="$agent-$i"
		# TODO we might need escaping in $cmd
		run 'tmux neww -t "$session_name" -n "$pane" -c "$treepath" "$cmd"'
		if [[ $ready_msg != "" ]] || [[ $unknown_agent == true ]]; then
			if [[ $ready_msg != "" ]]; then
				# TODO factor out the numbers everywhere
				for i in {1..25}; do
					capture=$(tmux capture-pane -t "$pane" -p)
					if grep -qF "$ready_msg" <<<"$capture"; then
						ready=true
						break
					fi
					sleep 0.2
				done
				if [[ $ready != true ]]; then
					echo "Agent '$agent' failed to initialize"
					continue
				fi
			else
				echo "Unknown agent '$agent', using hardcoded sleep interval: $INIT_SLEEP"
				sleep "$INIT_SLEEP"
			fi

			run 'tmux send-keys -t "$session_name:$pane" "$prompt"'
			sleep 0.1
			run 'tmux send-keys -t "$session_name:$pane" Enter'
		fi
	done
	echo "${#commands[@]} agents started"
	run 'tmux killp -t "$session_name:0"'
	run 'tmux a -t "$session_name"'
}

send() {
	# TODO show session details when asking for prompt; maybe in the chooser as well
	sessions=$(tmux ls -F '#S' | grep -F "$SESSION_PREFIX")
	if (($(wc -l <<<"$sessions") == 0)); then
		exit 1
	fi
	session_name=$(gum choose --header='Session:' <<<"$sessions")
	[[ -z $prompt ]] && prompt="$(gum write --header="Prompt ($session_name):")"

	panes=$(tmux list-p -st "$session_name" -F '#D')
	printf 'Sending: '

	# shellcheck disable=SC2034
	# used in `eval` inside `run`
	for pane in "${panes[@]}"; do
		run 'tmux send-keys -t "$pane" "$prompt"'
		sleep 0.1 # HACK gemini ignores enter otherwise
		run 'tmux send-keys -t "$pane" Enter'
		# TODO this looks ugly with dry run
		printf %s "$(gum style --trim --foreground="#00FF00" .)"
	done
	echo

	echo "Prompt sent to ${#commands[@]} agents"
}

case "${1:-}" in
	launch)
		shift
		argparse "$@"
		launch "$@"
		;;
	send)
		shift
		argparse "$@"
		send "$@"
		;;
	config)
		"$EDITOR" "$config_file"
		;;
	*)
		exit 1
		# TODO usage
		;;
esac
