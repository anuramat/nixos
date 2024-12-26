#!/usr/bin/env bash

main() {
	# reads .vim themes, writes terminal-sexy jsons to specified directory
	target_dir="$XDG_CONFIG_HOME/wallust/colorschemes"
	mkdir -p "$target_dir"

	binpath=$(realpath "$(command -v nvim)")
	vimdir="$(echo "$binpath" | cut -d / -f 1-4)"

	[ -d "$vimdir" ] || {
		echo "somehow the path doesn't exist"
		return 1
	}

	[ "$(echo "$vimdir" | cut -d / -f 2-3)" == "nix/store" ] || {
		echo "binary not in nix store"
		return 1
	}

	colordir="$vimdir/share/nvim/runtime/colors"

	while IFS= read -r -d '' filepath; do
		name=$(basename "$filepath" | sed 's/\.vim//')

		echo "writing $name"
		[ "$name" = default ] && continue

		# TODO use sed instead of ripgrep

		ansi=$(rg 'let\s+g:terminal_ansi_colors\s*=\s*(\[.*\])' "$filepath" -or '$1' \
			| tr "'" '"')
		# if more than one set of term colors (ie light/dark) - skip TODO read those too
		(($(echo "$ansi" | wc -l) > 1)) && echo "skipping $name: more than one set of colors found" && continue

		# original_name=$(rg '" Name:\s+(\S.*\S)\s*' "$filename" -or '$1')

		author=$(rg '" Author:\s+(\S.*\S)\s*' "$filepath" -or '$1')

		normal_line=$(rg 'hi\S*\s+Normal\s+' "$filepath")
		fg=$(echo "$normal_line" | rg 'guifg=(\S+)' -or '$1')
		bg=$(echo "$normal_line" | rg 'guibg=(\S+)' -or '$1')

		template='{"name": $name, "author": $author, "color": $ansi, "foreground": $fg, "background": $bg}'

		jq -n \
			--arg fg "$fg" \
			--arg bg "$bg" \
			--arg name "$name" \
			--arg author "$author" \
			--argjson ansi "$ansi" \
			"$template" 2> /dev/null > "$target_dir/$name.json" || echo "couldn't construct json for $name"
	done < <(find "$colordir" -mindepth 1 -name '*.vim' -print0)
}

main
