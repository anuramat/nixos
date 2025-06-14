#!/usr/bin/env bash
# Simple Neovim test script for Claude Code with screen capture

# Create temporary directories for XDG base directories
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

export XDG_CONFIG_HOME="$TMPDIR/.config"
export XDG_DATA_HOME="$TMPDIR/.local/share"
export XDG_STATE_HOME="$TMPDIR/.local/state"
export XDG_CACHE_HOME="$TMPDIR/.cache"

# Create necessary directories
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

# Set terminal environment
export TERM=xterm-256color
export COLUMNS=120
export LINES=30

# Test basic nvim functionality
echo "Testing Neovim configuration..."
echo "Using temporary directory: $TMPDIR"

# Capture screen content using script with timing
CAPTURE_FILE="$TMPDIR/nvim_session.txt"
TIMING_FILE="$TMPDIR/nvim_timing.txt"

echo "Capturing Neovim session..."

# Use script with timing to capture everything
script -t 2>"$TIMING_FILE" -a "$CAPTURE_FILE" -c "
timeout 10 nvim \
  -c 'echo \"=== Neovim Configuration Test ===\"' \
  -c 'echo \"Plugins loaded successfully\"' \
  -c 'echo \"Terminal size: \" . &columns . \"x\" . &lines' \
  -c 'redraw' \
  -c 'sleep 3' \
  -c 'quit'
" >/dev/null 2>&1

echo "Exit code: $?"
echo ""
echo "=== CAPTURED SCREEN CONTENT ==="
cat "$CAPTURE_FILE"
echo ""
echo "=== END CAPTURE ==="