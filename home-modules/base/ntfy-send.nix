# tgfy over the tailnet ntfy server
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.self.consts.ntfy) host port;
  ntfy-send = pkgs.writeShellApplication {
    name = "ntfy-send";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    runtimeEnv.url = "http://${host}:${toString port}/ntfy-send";
    text = ''
      usage() {
      	cat <<'EOF'
      Send notification over ntfy with optional file attachments.
      Reads the message from stdin. Silent on success; errors go to stderr.
      Exit code: 0 iff the message and all attachments were delivered.
      Usage:
        command | ntfy-send [file1 file2 ...]
      EOF
      }

      case "''${1-}" in
      	-h | --help)
      		usage
      		exit
      		;;
      	*) ;;
      esac

      fail=0
      err() {
      	echo "ntfy-send: $*" >&2
      	fail=1
      }

      if [ -t 0 ]; then
      	usage >&2
      	echo "ntfy-send: stdin is a terminal; pipe the message in" >&2
      	exit 1
      fi

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

      # publish with the given curl args to URL; report ntfy's .error on failure
      publish() {
      	local url=$1 resp msg
      	shift
      	if ! resp=$(curl -sS --max-time 60 --fail-with-body "$@" "$url" 2>&1); then
      		if ! msg=$(jq -er '.error' <<<"$resp" 2>/dev/null); then
      			msg=$resp
      		fi
      		err "$msg"
      	fi
      	return 0
      }

      # messages over ntfy's size limit arrive as a text attachment
      if [ "$TEXT" != "" ]; then
      	publish "$url" --data-binary "$TEXT"
      fi

      for file; do
      	publish "$url?filename=$(jq -rn --arg f "''${file##*/}" '$f | @uri')" -T "$file"
      done

      exit "$fail"
    '';
    inherit (config.lib.shellcheck) excludeShellChecks;
  };
in
{
  home.packages = [ ntfy-send ];
}
