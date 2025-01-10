#!/usr/bin/env bash

# set wallust theme, and apply post hooks
__wallust_wrapped() {
	local -r __wallust_cs_dir="$XDG_CONFIG_HOME/wallust/colorschemes"
	local -r __wallust_base_cmd="wallust -q"

	if [ "$1" = "sex" ]; then
		$__wallust_base_cmd cs -f terminal-sexy "$__wallust_cs_dir/$2.json" || return
	else
		$__wallust_base_cmd "$@" || return
	fi

	(
		cd "$XDG_CONFIG_HOME/mako" || {
			echo "Couldn't cd to the mako folder, skipping"
			exit
		}
		cat main.conf generated-colors.conf apps.conf > "./config"
		makoctl reload
	)

	# BUG reload somehow fucks up the terminal, sleep somehow helps
	# probably keyd causes problems
	sleep 0.03
	swaymsg reload
}
