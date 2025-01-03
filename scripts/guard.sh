#!/usr/bin/env bash

echo "Do you want to continue? (y/*)"
read -rn1 choice
[ "$choice" = y ] || exit 1
