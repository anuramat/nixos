#!/usr/bin/env bash

echo "summarizing files:"
fd -e txt --max-depth=1 -x echo $'\t''{}'

mkdir -p summaries
fd -e txt --max-depth=1 -x sh -c 'cat "{}" | mods -R summarizer > "./summaries/{.}.md"'
