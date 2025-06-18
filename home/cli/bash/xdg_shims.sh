#!/usr/bin/env sh
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history" # node.js
export STACK_ROOT="$XDG_DATA_HOME"/stack                    # Haskell stack (old)
export STACK_XDG=1                                          # Haskel stack (new variable, any non empty value will do)
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export DOT_SAGE="$XDG_CONFIG_HOME"/sage # sage math
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/pythonrc"
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export DVDCSS_CACHE="$XDG_DATA_HOME"/dvdcss    # VLC dependency
export MPLAYER_HOME="$XDG_CONFIG_HOME"/mplayer # I don't use this but somehow ended up with this in my $HOME anyway
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export PYTHONPYCACHEPREFIX="/tmp/pycache" # __pycache__ folder
export PYTHONUSERBASE="$XDG_DATA_HOME/python"
# NOTE .pyhistory is still hardcoded: https://github.com/python/cpython/pull/13208
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME/jupyter"
export IPYTHONDIR="$XDG_CONFIG_HOME/ipython"
