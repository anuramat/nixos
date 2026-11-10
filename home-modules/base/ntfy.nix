# `lib.ntfy.send NAME TOPIC`: a tgfy-like command NAME that publishes to TOPIC
# on the tailnet ntfy server
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.ntfy) host port;
  ntfySend =
    name: topic:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        curl
        jq
      ];
      runtimeEnv.url = "http://${host}:${toString port}/${topic}";
      text = ''
        usage() {
        	cat <<'EOF'
        Send notification to ntfy topic ${topic} with an optional title. Reads the
        message from stdin. Silent on success; errors go to stderr. Exit code: 0
        iff the notification was delivered.
        Usage:
          command | ${name} [-t title]
        EOF
        }

        title=""
        while getopts ht: opt; do
        	case $opt in
        	h)
        		usage
        		exit
        		;;
        	t) title=$OPTARG ;;
        	*)
        		usage >&2
        		exit 1
        		;;
        	esac
        done
        shift $((OPTIND - 1))

        fail=0
        err() {
        	echo "${name}: $*" >&2
        	fail=1
        }

        if [ "$#" -gt 0 ]; then
        	usage >&2
        	exit 1
        fi

        if [ -t 0 ]; then
        	usage >&2
        	echo "${name}: stdin is a terminal; pipe the message in" >&2
        	exit 1
        fi

        TEXT=$(cat)
        # ntfy turns messages of 4096 bytes and up into attachments
        if [ "$(
        	LC_ALL=C
        	echo "''${#TEXT}"
        )" -ge 4096 ]; then
        	err "message must be under 4096 bytes"
        fi
        if [ "$TEXT" = "" ]; then
        	err "nothing to send: empty stdin"
        fi

        if [ "$fail" -ne 0 ]; then
        	exit 1
        fi

        # a query param, since headers can't carry non-latin1 text
        if [ "$title" != "" ]; then
        	url="$url?title=$(jq -rn --arg t "$title" '$t | @uri')"
        fi

        # report ntfy's .error on failure
        if ! resp=$(curl -sS --max-time 60 --fail-with-body --data-binary "$TEXT" "$url" 2>&1); then
        	if ! msg=$(jq -er '.error' <<<"$resp" 2>/dev/null); then
        		msg=$resp
        	fi
        	err "$msg"
        fi

        exit "$fail"
      '';
      inherit (config.lib.shellcheck) excludeShellChecks;
    };
in
{
  lib.ntfy.send = ntfySend;
}
