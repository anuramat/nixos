#!/usr/bin/env bash

# get csv files

# TODO refactor
dir=data
[ "$(basename "$PWD")" = mime ] || exit 1
[ -f "$dir/media-types.xhtml" ] || wget -O "$dir/media-types.xhtml" https://www.iana.org/assignments/media-types/media-types.xhtml
while IFS= read -r link; do
	filename="$(basename "$link")"
	[ "$filename" = example.csv ] && continue
	[ -f "$dir/$filename" ] || {
		curl "$link" | csvcut -c Template | tail -n +2 >"$dir/$filename"
	}
done < <(htmlq -f "$dir/media-types.xhtml" -b https://www.iana.org/assignments/media-types -a href 'li > a' | sed s@#@/@ | sed 's/$/.csv/')

all=$(cat "$dir"/*.csv | sort | uniq)
defaultApplications=$(nix eval -f default.nix xdg.mime.defaultApplications --show-trace) || exit 1
mentioned=$(nix eval --raw --expr "let x = $defaultApplications; in x |> builtins.attrNames |> builtins.concatStringsSep \"\\n\"" | sort | uniq)

comm -23 <(echo "$mentioned") <(echo "$all")

# HUH, a lot of stuff is not in the csvs
# idk if validation even makes sense now
