#!/usr/bin/env bash

__say() {
	# usage: say_unwrapped "model" "text"
	[ -z "$XDG_CACHE_HOME" ] && echo 'empty $XDG_CACHE_HOME' && return 1
	local cache_dir="$XDG_CACHE_HOME/piper/"
	mkdir -p "$cache_dir"

	# https://github.com/rhasspy/piper/blob/master/VOICES.md
	# prefer medium quality, as high is too noisy
	#	robots:
	#	- ljspeech hm - 5/5, sc2 adjutant/mommy vibes, high pitch
	#	- libritts_r m - 5/5, the only natural sounding one
	#	- kristin m - 4/5, great, glados vibes, low pitch
	#	- bryce m - 4/5, jarvis vibes, male amy
	#	- amy ml - 3/5, monotone, sci-fi assistant vibes, high pitch
	local name="$1"
	local quality="medium" # low/medium/high
	local locale="en_US"

	local model_url="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/${locale:0:2}/$locale/$name/$quality/$locale-$name-$quality.onnx?download=true"
	local config_url="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/${locale:0:2}/$locale/$name/$quality/$locale-$name-$quality.onnx.json?download=true.json"
	local model_file="$cache_dir/$locale-$name-$quality.onnx"
	local config_file="$cache_dir/$locale-$name-$quality.json"

	[ -s "$model_file" ] || {
		printf '\n\tdownloading the model\n\n' && wget -q --show-progress -O "$model_file" "$model_url"
	} || {
		\printf '\terror, check the model name\n'
		rm "$model_file" && return 1
	}

	[ -s "$config_file" ] || {
		printf '\n\tdownloading the config\n\n' && wget -q --show-progress -O "$config_file" "$config_url"
	} || {
		\printf '\terror, check the model name\n'
		rm "$config_file" && return 1
	}

	echo "$2" \
		| piper --speaker 0 --length_scale 1 --noise_w 0 --noise_scale 0 --sentence_silence 0.3 -m "$model_file" -c "$config_file" -q -f -
}
say() {
	__say "libritts_r" "$*" | play -t wav -q -
}
