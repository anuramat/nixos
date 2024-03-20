#!/usr/bin/env bash
__ALWAYS_OVERWRITE="true"

ensure_path() {
	# $1 -- target path
	local -r target="$1"

	[ -d "$target" ] && return
	mkdir -p "$target" || {
		echo "[cfg.fail] create path \"$target\""
		return 1
	}
	echo "[cfg.write] created path \"$1\""
}

make_symlink() {
	# $1 -- source file
	# $2 -- target file/directory
	local -r original="$(realpath "$1")"
	local target="$2"

	[ -d "$target" ] && target="$target/$(basename "$original")"
	[ -e "$target" ] && { try_overwrite "$target" || return 1; }
	ln -sf "$original" "$target" || {
		echo "[cfg.fail] make symlink @ \"$target\""
		return 1
	}
	echo "[cfg.write] created symlink @ \"$target\""
}

install2folder() {
	local -r original="$(realpath "$1")"
	local -r target_dir="$2"

	[ -e "$1" ] || {
		echo "[cfg.fail] file \"$1\" not found!"
		return 1
	}

	ensure_path "$target_dir" || return 1
	install2file "$original" "$target_dir"
}

install2file() {
	# $1 -- source file
	# $2 -- target file
	local -r original="$(realpath "$1")"
	local -r target="$2"
	local -r target_dir="$(dirname "$2")"

	git check-ignore "$original" >/dev/null 2>&1 && {
		return
	}

	[ -e "$1" ] || {
		echo "[cfg.fail] file \"$1\" not found!"
		return 1
	}

	ensure_path "$target_dir" || return 1
	make_symlink "$original" "$target" || return 1
}

continue_prompt() {
	local -r prompt="$1"
	local choice
	while true; do
		printf "%s (y/n): " "$prompt"
		read -r choice
		case "$choice" in
			y | Y) return 0 ;;
			n | N) return 1 ;;
			*) echo "Invalid response" ;;
		esac
	done
}

try_overwrite() {
	# $1 -- target
	local -r target="$1"
	[ "$__ALWAYS_OVERWRITE" = "true" ] || continue_prompt "overwrite \"$target\"?" || return 1
	rm -rf "$target" || return 1
}