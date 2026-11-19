#!/usr/bin/env bash

brexit() {
	# set brightness for an external monitor (0-100)
	# usage: brexit 69
	ddcutil setvcp 10 "$1" --display 1
}
