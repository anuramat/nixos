#!/usr/bin/env bash

lipsum="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

# 1 paragraph is about 100 tokens
lipsum() {
	local n=$1

	if [ "$n" = 0 ]; then
		return
	fi

	result=""
	for ((i = 0; i < n; i++)); do
		result="$result $lipsum"
	done
	echo "$result"
}

measure_speed() {
	model=$1
	prompt=$2

	payload=$(mktemp)
	printf '%s' "$prompt" \
		| jq -n \
			--arg model "$model" \
			--rawfile prompt /dev/stdin \
			'{
				model: $model,
				messages: [
					{role: "system", content: "You are a helpful assistant."},
					{role: "user", content: $prompt}
				],
				max_tokens: 100
			}' >"$payload"

	out=$(
		curl -X POST http://localhost:11333/v1/chat/completions \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer dummy" \
			--data-binary "@$payload"
	)
	rm -f "$payload"

	input_tokens=$(echo "$out" | jq '.usage.prompt_tokens')
	output_tokens=$(echo "$out" | jq '.usage.completion_tokens')

	prompt_time=$(echo "$out" | jq '.time_info.prompt_time')
	completion_time=$(echo "$out" | jq '.time_info.completion_time')

	echo "Input: $input_tokens @ $(echo "$input_tokens / $prompt_time" | bc -l) t/s"
	echo "Output: $output_tokens @ $(echo "$output_tokens / $completion_time" | bc -l) t/s"
}

for n in 0 10 100 1000; do
	measure_speed "$1" "$(lipsum "$n") Tell me a story about a brave knight and a dragon."
	echo
done
