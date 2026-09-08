#!/usr/bin/env bash

usage() {
	cat <<'EOF'
Send notification over telegram with optional file attachments.
Reads the message from stdin. Silent on success; errors go to stderr.
Exit code: 0 iff the message and all attachments were delivered.
Usage:
  command | tgfy [file1 file2 ...]
EOF
}

case "${1-}" in
	-h | --help)
		usage
		exit
		;;
	*) ;;
esac

fail=0
err() {
	echo "tgfy: $*" >&2
	fail=1
}

if [ -t 0 ]; then
	usage >&2
	echo "tgfy: stdin is a terminal; pipe the message in" >&2
	exit 1
fi

for secret in /run/agenix/tgfy-id /run/agenix/tgfy-token; do
	if [ ! -r "$secret" ]; then
		err "cannot read $secret"
	fi
done

for file; do
	if [ ! -r "$file" ]; then
		err "no such file: $file"
	fi
done

TEXT=$(cat)
if [ "$TEXT" = "" ] && [ "$#" -eq 0 ]; then
	err "nothing to send: empty stdin and no files"
fi

if [ "$fail" -ne 0 ]; then
	exit 1
fi

CHAT_ID=$(cat /run/agenix/tgfy-id)
BOT_TOKEN=$(cat /run/agenix/tgfy-token)
API_URL="https://api.telegram.org/bot$BOT_TOKEN"

# call ENDPOINT with the given curl args; report telegram's .description on failure
api() {
	local endpoint=$1 resp msg
	shift
	if ! resp=$(curl -sS --max-time 60 "$@" "$API_URL/$endpoint" 2>&1); then
		err "$endpoint: curl: $resp"
		return 0
	fi
	if [ "$(jq -r '.ok' <<<"$resp" 2>/dev/null)" != "true" ]; then
		if ! msg=$(jq -er '.description' <<<"$resp" 2>/dev/null); then
			msg=$resp
		fi
		err "$endpoint: $msg"
	fi
	return 0
}

if [ "$TEXT" != "" ]; then
	# telegram caps messages at 4096 UTF-16 units; deliver a truncated
	# notification instead of failing outright
	if [ "${#TEXT}" -gt 3900 ]; then
		TEXT="${TEXT:0:3900}
[truncated]"
	fi
	api sendMessage -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT"
fi

for file; do
	api sendDocument -F chat_id="$CHAT_ID" -F document=@"$file"
done

exit "$fail"
