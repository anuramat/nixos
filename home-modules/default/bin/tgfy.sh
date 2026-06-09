#!/usr/bin/env bash

# text on stdin, files in args

CHAT_ID=$(cat /run/agenix/tgfy-id)
BOT_TOKEN=$(cat /run/agenix/tgfy-token)

echo "Run finished — FID 4.2" | curl -s \
	-d chat_id="$CHAT_ID" \
	--data-urlencode "text@-" \
	"https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

echo "Run finished — FID 4.2" | curl -s \
	-F chat_id="$CHAT_ID" \
	-F document=@"$1" \
	-F "caption=<-" \
	"https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
