#!/usr/bin/env bash

usage() {
	cat <<'EOF'
Send notification over telegram with optional file attachments.
No output = success.
Usage:
  command | tgfy.sh [file1 file2 ...]
EOF
}

case "${1-}" in
	-h | --help)
		usage
		exit
		;;
	*) ;;
esac

TEXT=$(cat)

CHAT_ID=$(cat /run/agenix/tgfy-id)
BOT_TOKEN=$(cat /run/agenix/tgfy-token)
API_URL="https://api.telegram.org/bot$BOT_TOKEN"

text_sent=$(curl -s \
	-d chat_id="$CHAT_ID" \
	--data-urlencode "text=$TEXT" \
	"$API_URL/sendMessage" | jq -r '.ok' -r)
[ "$text_sent" != "true" ] && echo "failed to send text message"

for file; do
	file_sent=$(curl -s \
		-F chat_id="$CHAT_ID" \
		-F document=@"$file" \
		"$API_URL/sendDocument" | jq -r '.ok' -r)
	[ "$file_sent" != "true" ] && echo "failed to send file: $file"
done
