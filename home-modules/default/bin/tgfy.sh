#!/usr/bin/env bash

usage() {
	cat <<'EOF'
Usage:
  tgfy.sh [-h|--help]
  command | tgfy.sh
  command | tgfy.sh FILE...
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

curl -s \
	-d chat_id="$CHAT_ID" \
	--data-urlencode "text=$TEXT" \
	"$API_URL/sendMessage"

for file; do
	curl -s \
		-F chat_id="$CHAT_ID" \
		-F document=@"$file" \
		"$API_URL/sendDocument"
done
