#!/usr/bin/env bash

set -e

SESSION_PREFIX='diriger'

# defaults
dry_run=false
feature=""
prompt=""
root=$PWD
commands=()
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/diriger"

argparse() {
	# parse arguments
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

	# fallback to interactive input or config file
	if [[ ${#commands[@]} -eq 0 ]]; then
		[[ ! -f $config_file ]] && {
			echo "Config file $config_file not found"
			exit 1
		}
		mapfile -t commands < "$config_file"
	fi
}

# execute command, showing it in dry run mode
run() {
	if $dry_run; then
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
	[[ -z $prompt ]] && prompt="$(gum write --header='Prompt:')"

	# launch the tmux session
	projname=$(basename "$root")
	session_name="$SESSION_PREFIX-$projname-$feature-$(uuidgen)"
	# TODO add project and feature to the session name
	echo "Session: $session_name"
	run 'tmux new -s "$session_name" -c "$root" -d'

	i=0
	for cmd in "${commands[@]}"; do
		((++i))
		agent=$(cut -d ' ' -f 1 <<< "$cmd")

		echo "Launching $cmd"

		treename="$projname-$feature-$agent-$i"
		run 'git worktree add "../$treename"'
		# shellcheck disable=SC2034
		# used in `eval` inside `run`
		treepath="$(realpath "../$treename")"

		# append the prompt
		if [[ -n $prompt ]]; then
			case "$agent" in
				gmn) cmd+=" -i '$prompt'" ;;
				ocd) cmd+=" -p '$prompt'" ;;
				cld) cmd+=" ' $prompt'" ;;
				*)
					echo "Invalid agent"
					exit 1
					;;
			esac
		fi

		# start the agent
		run 'tmux neww -t "$session_name" -n "$agent-$i" -c "$treepath" "$cmd"'
	done
	echo "${#commands[@]} agents started"
	run 'tmux killp -t "$session_name:0"'
	run 'tmux a -t "$session_name"'
}

send() {
	# TODO show session details when asking for prompt; maybe in the chooser as well
	sessions=$(tmux ls -F '#S' | grep -F "$SESSION_PREFIX")
	if (($(wc -l <<< "$sessions") == 0)); then
		exit 1
	fi
	session_name=$(gum choose --header='Session:' <<< "$sessions")
	[[ -z $prompt ]] && prompt="$(gum write --header='Prompt:')"

	panes=$(tmux list-p -st "$session_name" -F '#D')
	printf 'Sending: '
	for pane in $panes; do
		run 'tmux send-keys -t "$pane" "$prompt"'
		sleep 0.1 # HACK gemini ignores enter otherwise
		run 'tmux send-keys -t "$pane" Enter'
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
	*)
		exit 1
		# TODO usage
		;;
esac
