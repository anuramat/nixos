#!/usr/bin/env bash

__osc133() {
	printf '\e]133;A\e\\'
}
__osc7() {
	local strlen=${#PWD}
	local encoded=""
	local pos c o
	for ((pos = 0; pos < strlen; pos++)); do
		c=${PWD:pos:1}
		case "$c" in
			[-/:_.!\'\(\)~[:alnum:]]) o="${c}" ;;
			*) printf -v o '%%%02X' "'${c}" ;;
		esac
		encoded+="${o}"
	done
	printf '\e]7;file://%s%s\e\\' "${HOSTNAME}" "${encoded}"
}

PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}__osc7;__osc133"
