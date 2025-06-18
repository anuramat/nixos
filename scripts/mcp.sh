#!/usr/bin/env bash

temp=$(mktemp)
jq --slurpfile mcp ./mcp.json '.mcpServers = $mcp[0]' "$HOME/.claude.json" > "$temp" && mv "$temp" "$HOME/.claude.json"
