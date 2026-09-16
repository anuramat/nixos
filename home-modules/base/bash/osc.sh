#!/usr/bin/env bash

# prompt zones: A start of prompt, B end of prompt, C start of output, D end of output
# must be sourced after starship: precmd runs before starship_precmd (needs $?),
# ps1 runs after it (appends to the PS1 it generates)
__osc133_preexec() {
	printf '\e]133;C\e\\'
	__osc133_ran=1
}
__osc133_precmd() {
	# shellcheck disable=SC2034 # one command: starship reads both $? and BP_PIPESTATUS after we return
	__osc133_ret=$? BP_PIPESTATUS=("${PIPESTATUS[@]}")
	[[ -n $__osc133_ran ]] && printf '\e]133;D;%s\e\\' "$__osc133_ret"
	__osc133_ran=
	printf '\e]133;A\e\\'
	return "$__osc133_ret"
}
__osc133_ps1() {
	PS1+='\[\e]133;B\e\\\]'
}

# cwd
__osc7() {
	local strlen=${#PWD}
	local encoded=""
	local pos c o
	for ((pos = 0; pos < strlen; pos++)); do
		c=${PWD:pos:1}
		case "$c" in
			[-/:_.!\'\(\)~[:alnum:]]) o="$c" ;;
			*) printf -v o '%%%02X' "'${c}" ;;
		esac
		encoded+="$o"
	done
	printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$encoded"
}

PS0='${ __osc133_preexec; }'"$PS0"
PROMPT_COMMAND="__osc133_precmd;${PROMPT_COMMAND:+$PROMPT_COMMAND;}__osc133_ps1;__osc7"
