#!/usr/bin/env bash

fst=$(sort -u "$1")
root=$(sort -u "$2")
snd=$(sort -u "$3")

all=$(printf "%s\n" "$fst" "$snd" | sort -u)
common=$(comm -12 <(echo "$fst") <(echo "$snd") | sort -u)
deleted=$(comm -23 <(echo "$root") <(echo $common))

echo "$deleted" | grep -vxF -f - <(printf '%s' "$all") | awk NF | sort -u > "$1"
