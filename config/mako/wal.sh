#!/usr/bin/env bash

cat "$XDG_CONFIG_HOME/mako/input.conf" "$XDG_CONFIG_HOME/mako/generated-colors" >"$XDG_CONFIG_HOME/mako/config"
makoctl reload