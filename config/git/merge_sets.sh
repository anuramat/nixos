#!/usr/bin/env bash

export LC_ALL=C

fst=$(sort -u "$1")
root=$(sort -u "$2")
snd=$(sort -u "$3")

all=$(printf "%s\n" "$fst" "$snd" | sort -u)
intersection=$(comm -12 <(echo "$fst") <(echo "$snd") | sort -u)
deleted=$(comm -23 <(echo "$root") <(echo "$intersection") | sort -u)
res=$(comm -23 <(echo "$all") <(echo "$deleted"))

echo "$res" | awk NF | sort -u
