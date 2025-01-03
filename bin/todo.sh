#!/usr/bin/env bash
# shellcheck disable=all

TODOTXT_SILENT_ARCHIVE=1

# HEAVY LIFTING {{{1
shopt -s extglob extquote

# Set script name and full path early.
TODO_SH=$(basename "$0")
TODO_FULL_SH="$0"
export TODO_SH TODO_FULL_SH

die() {
	echo "$*"
	exit 1
}

cleaninput() {
	# Parameters:    When $1 = "for sed", performs additional escaping for use
	#                in sed substitution with "|" separators.
	# Precondition:  $input contains text to be cleaned.
	# Postcondition: Modifies $input.

	# Replace CR and LF with space; tasks always comprise a single line.
	input=${input//$'\r'/ }
	input=${input//$'\n'/ }

	if [ "$1" = "for sed" ]; then
		# This action uses sed with "|" as the substitution separator, and & as
		# the matched string; these must be escaped.
		# Backslashes must be escaped, too, and before the other stuff.
		input=${input//\\/\\\\}
		input=${input//|/\\|}
		input=${input//&/\\&}
	fi
}

getPrefix() {
	# Parameters:    $1: todo file; empty means $TODO_FILE.
	# Returns:       Uppercase FILE prefix to be used in place of "TODO:" where
	#                a different todo file can be specified.
	local base
	base=$(basename "${1:-$TODO_FILE}")
	echo "${base%%.[^.]*}" | tr '[:lower:]' '[:upper:]'
}

getTodo() {
	# Parameters:    $1: task number
	#                $2: Optional todo file
	# Precondition:  $errmsg contains usage message.
	# Postcondition: $todo contains task text.

	local item=$1
	[ -z "$item" ] && die "$errmsg"
	[ "${item//[0-9]/}" ] && die "$errmsg"

	todo=$(sed "$item!d" "${2:-$TODO_FILE}")
	[ -z "$todo" ] && die "$(getPrefix "$2"): No task $item."
}

getNewtodo() {
	# Parameters:    $1: task number
	#                $2: Optional todo file
	# Precondition:  None.
	# Postcondition: $newtodo contains task text.

	local item=$1
	[ -z "$item" ] && die "Programming error: $item should exist."
	[ "${item//[0-9]/}" ] && die "Programming error: $item should be numeric."

	newtodo=$(sed "$item!d" "${2:-$TODO_FILE}")
	[ -z "$newtodo" ] && die "$(getPrefix "$2"): No updated task $item."
}

replaceOrPrepend() {
	action=$1
	shift
	case "$action" in
		replace)
			backref=
			querytext="Replacement: "
			;;
		prepend)
			backref=' &'
			querytext="Prepend: "
			;;
	esac
	shift
	item=$1
	shift
	getTodo "$item"

	if [[ -z $1 && $TODOTXT_FORCE == 0 ]]; then
		echo -n "$querytext"
		read -r -i "$todo" -e input
	else
		input=$*
	fi

	# Retrieve existing priority and prepended date
	local -r priAndDateExpr='^\((.) \)\{0,1\}\([0-9]\{2,4\}-[0-9]\{2\}-[0-9]\{2\} \)\{0,1\}'
	priority=$(sed -e "$item!d" -e "${item}s/${priAndDateExpr}.*/\\1/" "$TODO_FILE")
	prepdate=$(sed -e "$item!d" -e "${item}s/${priAndDateExpr}.*/\\2/" "$TODO_FILE")

	if [ "$prepdate" ] && [ "$action" = "replace" ] && [ "$(echo "$input" | sed -e "s/${priAndDateExpr}.*/\\1\\2/")" ]; then
		# If the replaced text starts with a [priority +] date, it will replace
		# the existing date, too.
		prepdate=
	fi

	# Temporarily remove any existing priority and prepended date, perform the
	# change (replace/prepend) and re-insert the existing priority and prepended
	# date again.
	cleaninput "for sed"
	sed -i.bak -e "$item s/^${priority}${prepdate}//" -e "$item s|^.*|${priority}${prepdate}${input}${backref}|" "$TODO_FILE"
	if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
		getNewtodo "$item"
		case "$action" in
			replace)
				echo "$item $todo"
				echo "TODO: Replaced task with:"
				echo "$item $newtodo"
				;;
			prepend)
				echo "$item $newtodo"
				;;
		esac
	fi
}

fixMissingEndOfLine() {
	# Parameters:    $1: todo file; empty means $TODO_FILE.
	sed -i.bak -e '$a\' "${1:-$TODO_FILE}"
}

uppercasePriority() {
	# Precondition:  $input contains task text for which to uppercase priority.
	# Postcondition: Modifies $input.
	lower=({a..z})
	upper=({A..Z})
	for ((i = 0; i < 26; i++)); do
		upperPriority="${upperPriority};s/^[(]${lower[i]}[)]/(${upper[i]})/"
	done
	input=$(echo "$input" | sed "$upperPriority")
}

#Preserving environment variables so they don't get clobbered by the config file
OVR_TODOTXT_FORCE="$TODOTXT_FORCE"
OVR_TODOTXT_PRESERVE_LINE_NUMBERS="$TODOTXT_PRESERVE_LINE_NUMBERS"
OVR_TODOTXT_PLAIN="$TODOTXT_PLAIN"
OVR_TODOTXT_DATE_ON_ADD="$TODOTXT_DATE_ON_ADD"
OVR_TODOTXT_PRIORITY_ON_ADD="$TODOTXT_PRIORITY_ON_ADD"
OVR_TODOTXT_DISABLE_FILTER="$TODOTXT_DISABLE_FILTER"
OVR_TODOTXT_VERBOSE="$TODOTXT_VERBOSE"
OVR_TODOTXT_DEFAULT_ACTION="$TODOTXT_DEFAULT_ACTION"
OVR_TODOTXT_SORT_COMMAND="$TODOTXT_SORT_COMMAND"
OVR_TODOTXT_FINAL_FILTER="$TODOTXT_FINAL_FILTER"

# Prevent GREP_OPTIONS from malforming grep's output
export GREP_OPTIONS=""

# PROCESS OPTIONS {{{1
while getopts ":fhpcnNaAtTvVx+@Pd:" Option; do
	case $Option in
		'@')
			## HIDE_CONTEXT_NAMES starts at zero (false); increment it to one
			##   (true) the first time this flag is seen. Each time the flag
			##   is seen after that, increment it again so that an even
			##   number shows context names and an odd number hides context
			##   names.
			: $((HIDE_CONTEXT_NAMES++))
			if [ $((HIDE_CONTEXT_NAMES % 2)) -eq 0 ]; then
				## Zero or even value -- show context names
				unset HIDE_CONTEXTS_SUBSTITUTION
			else
				## One or odd value -- hide context names
				export HIDE_CONTEXTS_SUBSTITUTION='[[:space:]]@[[:graph:]]\{1,\}'
			fi
			;;
		'+')
			## HIDE_PROJECT_NAMES starts at zero (false); increment it to one
			##   (true) the first time this flag is seen. Each time the flag
			##   is seen after that, increment it again so that an even
			##   number shows project names and an odd number hides project
			##   names.
			: $((HIDE_PROJECT_NAMES++))
			if [ $((HIDE_PROJECT_NAMES % 2)) -eq 0 ]; then
				## Zero or even value -- show project names
				unset HIDE_PROJECTS_SUBSTITUTION
			else
				## One or odd value -- hide project names
				export HIDE_PROJECTS_SUBSTITUTION='[[:space:]][+][[:graph:]]\{1,\}'
			fi
			;;
		c)
			OVR_TODOTXT_PLAIN=0
			;;
		d)
			TODOTXT_CFG_FILE=$OPTARG
			;;
		f)
			OVR_TODOTXT_FORCE=1
			;;
		n)
			OVR_TODOTXT_PRESERVE_LINE_NUMBERS=0
			;;
		N)
			OVR_TODOTXT_PRESERVE_LINE_NUMBERS=1
			;;
		p)
			OVR_TODOTXT_PLAIN=1
			;;
		P)
			## HIDE_PRIORITY_LABELS starts at zero (false); increment it to one
			##   (true) the first time this flag is seen. Each time the flag
			##   is seen after that, increment it again so that an even
			##   number shows priority labels and an odd number hides priority
			##   labels.
			: $((HIDE_PRIORITY_LABELS++))
			if [ $((HIDE_PRIORITY_LABELS % 2)) -eq 0 ]; then
				## Zero or even value -- show priority labels
				unset HIDE_PRIORITY_SUBSTITUTION
			else
				## One or odd value -- hide priority labels
				export HIDE_PRIORITY_SUBSTITUTION="([A-Z])[[:space:]]"
			fi
			;;
		t)
			OVR_TODOTXT_DATE_ON_ADD=1
			;;
		T)
			OVR_TODOTXT_DATE_ON_ADD=0
			;;
		v)
			: $((TODOTXT_VERBOSE++))
			;;
		V)
			version
			;;
		x)
			OVR_TODOTXT_DISABLE_FILTER=1
			;;
		*)
			die "huh"
			;;
	esac
done
shift $((OPTIND - 1))

# defaults if not yet defined
TODOTXT_VERBOSE=${TODOTXT_VERBOSE:-1}
TODOTXT_PLAIN=${TODOTXT_PLAIN:-0}
TODOTXT_CFG_FILE=${TODOTXT_CFG_FILE:-$HOME/.todo/config}
TODOTXT_FORCE=${TODOTXT_FORCE:-0}
TODOTXT_PRESERVE_LINE_NUMBERS=${TODOTXT_PRESERVE_LINE_NUMBERS:-1}
TODOTXT_DATE_ON_ADD=${TODOTXT_DATE_ON_ADD:-0}
TODOTXT_PRIORITY_ON_ADD=${TODOTXT_PRIORITY_ON_ADD:-}
TODOTXT_DEFAULT_ACTION=${TODOTXT_DEFAULT_ACTION:-}
TODOTXT_SORT_COMMAND=${TODOTXT_SORT_COMMAND:-env LC_COLLATE=C sort -f -k2}
TODOTXT_DISABLE_FILTER=${TODOTXT_DISABLE_FILTER:-}
TODOTXT_FINAL_FILTER=${TODOTXT_FINAL_FILTER:-cat}
TODOTXT_GLOBAL_CFG_FILE=${TODOTXT_GLOBAL_CFG_FILE:-/etc/todo/config}
TODOTXT_SIGIL_BEFORE_PATTERN=${TODOTXT_SIGIL_BEFORE_PATTERN:-} # Allow any other non-whitespace entity before +project and @context; should be an optional match; example: \(w:\)\{0,1\} to allow w:@context.
TODOTXT_SIGIL_VALID_PATTERN=${TODOTXT_SIGIL_VALID_PATTERN:-.*} # Limit the valid characters (from the default any non-whitespace sequence) for +project and @context; example: [a-zA-Z]\{3,\} to only allow alphabetic ones that are at least three characters long.
TODOTXT_SIGIL_AFTER_PATTERN=${TODOTXT_SIGIL_AFTER_PATTERN:-}   # Allow any other non-whitespace entity after +project and @context; should be an optional match; example: )\{0,1\} to allow (with the corresponding TODOTXT_SIGIL_BEFORE_PATTERN) enclosing in parentheses.

# Export all TODOTXT_* variables
export "${!TODOTXT_@}"

# Default color map
export NONE=''
export BLACK='\\033[0;30m'
export RED='\\033[0;31m'
export GREEN='\\033[0;32m'
export BROWN='\\033[0;33m'
export BLUE='\\033[0;34m'
export PURPLE='\\033[0;35m'
export CYAN='\\033[0;36m'
export LIGHT_GREY='\\033[0;37m'
export DARK_GREY='\\033[1;30m'
export LIGHT_RED='\\033[1;31m'
export LIGHT_GREEN='\\033[1;32m'
export YELLOW='\\033[1;33m'
export LIGHT_BLUE='\\033[1;34m'
export LIGHT_PURPLE='\\033[1;35m'
export LIGHT_CYAN='\\033[1;36m'
export WHITE='\\033[1;37m'
export DEFAULT='\\033[0m'

# Default priority->color map.
export PRI_A=$YELLOW     # color for A priority
export PRI_B=$GREEN      # color for B priority
export PRI_C=$LIGHT_BLUE # color for C priority
export PRI_X=$WHITE      # color unless explicitly defined

# Default project, context, date, item number, and metadata key:value pairs colors.
export COLOR_PROJECT=$NONE
export COLOR_CONTEXT=$NONE
export COLOR_DATE=$NONE
export COLOR_NUMBER=$NONE
export COLOR_META=$NONE

# Default highlight colors.
export COLOR_DONE=$LIGHT_GREY # color for done (but not yet archived) tasks

# Default sentence delimiters for todo.sh append.
# If the text to be appended to the task begins with one of these characters, no
# whitespace is inserted in between. This makes appending to an enumeration
# (todo.sh add 42 ", foo") syntactically correct.
export SENTENCE_DELIMITERS=',.:;'

[ -e "$TODOTXT_CFG_FILE" ] || {
	CFG_FILE_ALT="$HOME/todo.cfg"

	if [ -e "$CFG_FILE_ALT" ]; then
		TODOTXT_CFG_FILE="$CFG_FILE_ALT"
	fi
}

[ -e "$TODOTXT_CFG_FILE" ] || {
	CFG_FILE_ALT="$HOME/.todo.cfg"

	if [ -e "$CFG_FILE_ALT" ]; then
		TODOTXT_CFG_FILE="$CFG_FILE_ALT"
	fi
}

[ -e "$TODOTXT_CFG_FILE" ] || {
	CFG_FILE_ALT="${XDG_CONFIG_HOME:-$HOME/.config}/todo/config"

	if [ -e "$CFG_FILE_ALT" ]; then
		TODOTXT_CFG_FILE="$CFG_FILE_ALT"
	fi
}

[ -e "$TODOTXT_CFG_FILE" ] || {
	CFG_FILE_ALT=$(dirname "$0")"/todo.cfg"

	if [ -e "$CFG_FILE_ALT" ]; then
		TODOTXT_CFG_FILE="$CFG_FILE_ALT"
	fi
}

[ -e "$TODOTXT_CFG_FILE" ] || {
	CFG_FILE_ALT="$TODOTXT_GLOBAL_CFG_FILE"

	if [ -e "$CFG_FILE_ALT" ]; then
		TODOTXT_CFG_FILE="$CFG_FILE_ALT"
	fi
}

if [ -z "$TODO_ACTIONS_DIR" ] || [ ! -d "$TODO_ACTIONS_DIR" ]; then
	TODO_ACTIONS_DIR="$HOME/.todo/actions"
	export TODO_ACTIONS_DIR
fi

[ -d "$TODO_ACTIONS_DIR" ] || {
	TODO_ACTIONS_DIR_ALT="$HOME/.todo.actions.d"

	if [ -d "$TODO_ACTIONS_DIR_ALT" ]; then
		TODO_ACTIONS_DIR="$TODO_ACTIONS_DIR_ALT"
	fi
}

[ -d "$TODO_ACTIONS_DIR" ] || {
	TODO_ACTIONS_DIR_ALT="${XDG_CONFIG_HOME:-$HOME/.config}/todo/actions"

	if [ -d "$TODO_ACTIONS_DIR_ALT" ]; then
		TODO_ACTIONS_DIR="$TODO_ACTIONS_DIR_ALT"
	fi
}

# SANITY CHECKS (thanks Karl!) {{{1
[ -r "$TODOTXT_CFG_FILE" ] || die "$1" "Fatal Error: Cannot read configuration file $TODOTXT_CFG_FILE"

. "$TODOTXT_CFG_FILE"

# APPLY OVERRIDES {{{1
if [ -n "$OVR_TODOTXT_FORCE" ]; then
	TODOTXT_FORCE="$OVR_TODOTXT_FORCE"
fi
if [ -n "$OVR_TODOTXT_PRESERVE_LINE_NUMBERS" ]; then
	TODOTXT_PRESERVE_LINE_NUMBERS="$OVR_TODOTXT_PRESERVE_LINE_NUMBERS"
fi
if [ -n "$OVR_TODOTXT_PLAIN" ]; then
	TODOTXT_PLAIN="$OVR_TODOTXT_PLAIN"
fi
if [ -n "$OVR_TODOTXT_DATE_ON_ADD" ]; then
	TODOTXT_DATE_ON_ADD="$OVR_TODOTXT_DATE_ON_ADD"
fi
if [ -n "$OVR_TODOTXT_PRIORITY_ON_ADD" ]; then
	TODOTXT_PRIORITY_ON_ADD="$OVR_TODOTXT_PRIORITY_ON_ADD"
fi
if [ -n "$OVR_TODOTXT_DISABLE_FILTER" ]; then
	TODOTXT_DISABLE_FILTER="$OVR_TODOTXT_DISABLE_FILTER"
fi
if [ -n "$OVR_TODOTXT_VERBOSE" ]; then
	TODOTXT_VERBOSE="$OVR_TODOTXT_VERBOSE"
fi
if [ -n "$OVR_TODOTXT_DEFAULT_ACTION" ]; then
	TODOTXT_DEFAULT_ACTION="$OVR_TODOTXT_DEFAULT_ACTION"
fi
if [ -n "$OVR_TODOTXT_SORT_COMMAND" ]; then
	TODOTXT_SORT_COMMAND="$OVR_TODOTXT_SORT_COMMAND"
fi
if [ -n "$OVR_TODOTXT_FINAL_FILTER" ]; then
	TODOTXT_FINAL_FILTER="$OVR_TODOTXT_FINAL_FILTER"
fi

ACTION=${1:-$TODOTXT_DEFAULT_ACTION}

[ -z "$ACTION" ] && die
[ -d "$TODO_DIR" ] || mkdir -p "$TODO_DIR" 2> /dev/null || die "$1" "Fatal Error: $TODO_DIR is not a directory"
(cd "$TODO_DIR") || die "$1" "Fatal Error: Unable to cd to $TODO_DIR"
[ -z "$TODOTXT_PRIORITY_ON_ADD" ] \
	|| echo "$TODOTXT_PRIORITY_ON_ADD" | grep -q "^[A-Z]$" \
	|| die "TODOTXT_PRIORITY_ON_ADD should be a capital letter from A to Z (it is now \"$TODOTXT_PRIORITY_ON_ADD\")."

[ -z "$TODO_FILE" ] && TODO_FILE="$TODO_DIR/todo.txt"
[ -z "$DONE_FILE" ] && DONE_FILE="$TODO_DIR/done.txt"
[ -z "$REPORT_FILE" ] && REPORT_FILE="$TODO_DIR/report.txt"

[ -f "$TODO_FILE" ] || [ -c "$TODO_FILE" ] || > "$TODO_FILE"
[ -f "$DONE_FILE" ] || [ -c "$DONE_FILE" ] || > "$DONE_FILE"
[ -f "$REPORT_FILE" ] || [ -c "$REPORT_FILE" ] || > "$REPORT_FILE"

if [ $TODOTXT_PLAIN = 1 ]; then
	for clr in ${!PRI_@}; do
		export "$clr"=$NONE
	done
	PRI_X=$NONE
	DEFAULT=$NONE
	COLOR_DONE=$NONE
	COLOR_PROJECT=$NONE
	COLOR_CONTEXT=$NONE
	COLOR_DATE=$NONE
	COLOR_NUMBER=$NONE
	COLOR_META=$NONE
fi

[[ "$HIDE_PROJECTS_SUBSTITUTION" ]] && COLOR_PROJECT="$NONE"
[[ "$HIDE_CONTEXTS_SUBSTITUTION" ]] && COLOR_CONTEXT="$NONE"

_addto() {
	file="$1"
	input="$2"
	cleaninput
	uppercasePriority

	if [[ $TODOTXT_DATE_ON_ADD -eq 1 ]]; then
		now=$(date '+%Y-%m-%d')
		input=$(echo "$input" | sed -e 's/^\(([A-Z]) \)\{0,1\}/\1'"$now /")
	fi
	if [[ -n $TODOTXT_PRIORITY_ON_ADD ]]; then
		if ! echo "$input" | grep -q '^([A-Z])'; then
			input=$(
				echo -n "($TODOTXT_PRIORITY_ON_ADD) "
				echo "$input"
			)
		fi
	fi
	fixMissingEndOfLine "$file"
	echo "$input" >> "$file"
	if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
		TASKNUM=$(sed -n '$ =' "$file")
		echo "$TASKNUM $input"
		echo "$(getPrefix "$file"): $TASKNUM added."
	fi
}

shellquote() {
	typeset -r qq=\'
	printf %s\\n "'${1//\'/${qq}\\${qq}${qq}}'"
}

filtercommand() {
	filter=${1:-}
	shift
	post_filter=${1:-}
	shift

	for search_term; do
		## See if the first character of $search_term is a dash
		if [ "${search_term:0:1}" != '-' ]; then
			## First character isn't a dash: hide lines that don't match
			## this $search_term
			filter="${filter:-}${filter:+ | }grep -i $(shellquote "$search_term")"
		else
			## First character is a dash: hide lines that match this
			## $search_term
			#
			## Remove the first character (-) before adding to our filter command
			filter="${filter:-}${filter:+ | }grep -v -i $(shellquote "${search_term:1}")"
		fi
	done

	[ -n "$post_filter" ] && {
		filter="${filter:-}${filter:+ | }${post_filter:-}"
	}

	printf %s "$filter"
}

_list() {
	local FILE="$1"
	## If the file starts with a "/" use absolute path. Otherwise,
	## try to find it in either $TODO_DIR or using a relative path
	if [ "${1:0:1}" == / ]; then
		## Absolute path
		src="$FILE"
	elif [ -f "$TODO_DIR/$FILE" ]; then
		## Path relative to todo.sh directory
		src="$TODO_DIR/$FILE"
	elif [ -f "$FILE" ]; then
		## Path relative to current working directory
		src="$FILE"
	elif [ -f "$TODO_DIR/${FILE}.txt" ]; then
		## Path relative to todo.sh directory, missing file extension
		src="$TODO_DIR/${FILE}.txt"
	else
		die "TODO: File $FILE does not exist."
	fi

	## Get our search arguments, if any
	shift ## was file name, new $1 is first search term

	_format "$src" '' "$@"

	if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
		echo "--"
		echo "$(getPrefix "$src"): ${NUMTASKS:-0} of ${TOTALTASKS:-0} tasks shown"
	fi
}
getPadding() {
	## We need one level of padding for each power of 10 $LINES uses.
	LINES=$(sed -n '$ =' "${1:-$TODO_FILE}")
	printf %s ${#LINES}
}
_format() {
	# Parameters:    $1: todo input file; when empty formats stdin
	#                $2: ITEM# number width; if empty auto-detects from $1 / $TODO_FILE.
	# Precondition:  None
	# Postcondition: $NUMTASKS and $TOTALTASKS contain statistics (unless $TODOTXT_VERBOSE=0).

	FILE=$1
	shift

	## Figure out how much padding we need to use, unless this was passed to us.
	PADDING=${1:-$(getPadding "$FILE")}
	shift

	## Number the file, then run the filter command,
	## then sort and mangle output some more
	if [[ $TODOTXT_DISABLE_FILTER == 1 ]]; then
		TODOTXT_FINAL_FILTER="cat"
	fi
	items=$(
		if [ "$FILE" ]; then
			sed = "$FILE"
		else
			sed =
		fi \
			| sed -e '''
            N
            s/^/     /
            s/ *\([ 0-9]\{'"$PADDING"',\}\)\n/\1 /
            /^[ 0-9]\{1,\} *$/d
         '''
	)

	## Build and apply the filter.
	filter_command=$(filtercommand "${pre_filter_command:-}" "${post_filter_command:-}" "$@")
	if [ "${filter_command}" ]; then
		filtered_items=$(echo -n "$items" | eval "${filter_command}")
	else
		filtered_items=$items
	fi
	filtered_items=$(
		echo -n "$filtered_items" \
			| sed '''
            s/^     /00000/;
            s/^    /0000/;
            s/^   /000/;
            s/^  /00/;
            s/^ /0/;
          ''' \
			| eval "${TODOTXT_SORT_COMMAND}" \
			| awk '''
            function highlight(colorVar,      color) {
                color = ENVIRON[colorVar]
                gsub(/\\+033/, "\033", color)
                return color
            }
            {
                clr = ""
                if (match($0, /^[0-9]+ x /)) {
                    clr = highlight("COLOR_DONE")
                } else if (match($0, /^[0-9]+ \([A-Z]\) /)) {
                    clr = highlight("PRI_" substr($0, RSTART + RLENGTH - 3, 1))
                    clr = (clr ? clr : highlight("PRI_X"))
                    if (ENVIRON["HIDE_PRIORITY_SUBSTITUTION"] != "") {
                        $0 = substr($0, 1, RLENGTH - 4) substr($0, RSTART + RLENGTH)
                    }
                }
                end_clr = (clr ? highlight("DEFAULT") : "")

                prj_beg = highlight("COLOR_PROJECT")
                prj_end = (prj_beg ? (highlight("DEFAULT") clr) : "")

                ctx_beg = highlight("COLOR_CONTEXT")
                ctx_end = (ctx_beg ? (highlight("DEFAULT") clr) : "")

                dat_beg = highlight("COLOR_DATE")
                dat_end = (dat_beg ? (highlight("DEFAULT") clr) : "")

                num_beg = highlight("COLOR_NUMBER")
                num_end = (num_beg ? (highlight("DEFAULT") clr) : "")

                met_beg = highlight("COLOR_META")
                met_end = (met_beg ? (highlight("DEFAULT") clr) : "")

                gsub(/[ \t][ \t]*/, "\n&\n")
                len = split($0, words, /\n/)

                printf "%s", clr
                for (i = 1; i <= len; ++i) {
                    if (i == 1 && words[i] ~ /^[0-9]+$/ ) {
                        printf "%s", num_beg words[i] num_end
                    } else if (words[i] ~ /^[+].*[A-Za-z0-9_]$/) {
                        printf "%s", prj_beg words[i] prj_end
                    } else if (words[i] ~ /^[@].*[A-Za-z0-9_]$/) {
                        printf "%s", ctx_beg words[i] ctx_end
                    } else if (words[i] ~ /^(19|20)[0-9]{2}-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])$/) {
                        printf "%s", dat_beg words[i] dat_end
                    } else if (words[i] ~ /^[[:alnum:]]+:[^ ]+$/) {
                        printf "%s", met_beg words[i] met_end
                    } else {
                        printf "%s", words[i]
                    }
                }
                printf "%s\n", end_clr
            }
          ''' \
			| sed '''
            s/'"${HIDE_PROJECTS_SUBSTITUTION:-^}"'//g
            s/'"${HIDE_CONTEXTS_SUBSTITUTION:-^}"'//g
            s/'"${HIDE_CUSTOM_SUBSTITUTION:-^}"'//g
          ''' \
			| eval ${TODOTXT_FINAL_FILTER}
	)
	[ "$filtered_items" ] && echo "$filtered_items"

	if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
		NUMTASKS=$(echo -n "$filtered_items" | sed -n '$ =')
		TOTALTASKS=$(echo -n "$items" | sed -n '$ =')
	fi
	if [ "$TODOTXT_VERBOSE" -gt 1 ]; then
		echo "TODO DEBUG: Filter Command was: ${filter_command:-cat}"
	fi
}

listWordsWithSigil() {
	sigil=$1
	shift

	FILE=$TODO_FILE
	[ "$TODOTXT_SOURCEVAR" ] && eval "FILE=$TODOTXT_SOURCEVAR"
	eval "$(filtercommand 'cat "${FILE[@]}"' '' "$@")" \
		| grep -o "[^ ]*${sigil}[^ ]\\+" \
		| sed -n \
			-e "s#^${TODOTXT_SIGIL_BEFORE_PATTERN//#/\\#}##" \
			-e "s#${TODOTXT_SIGIL_AFTER_PATTERN//#/\\#}\$##" \
			-e "/^${sigil}${TODOTXT_SIGIL_VALID_PATTERN//\//\\/}$/p" \
		| sort -u
}

listTasksWithoutSigil() {
	post_filter_command="${post_filter_command:-}${post_filter_command:+ | }grep -vP -- '(?<!\S)\\$1\S*'"
	shift
	_list "$TODO_FILE" "$@"
}

export -f cleaninput getPrefix getTodo getNewtodo shellquote filtercommand _list listWordsWithSigil getPadding _format die

# HANDLE ACTION {{{1
action=$(printf "%s\n" "$ACTION" | tr '[:upper:]' '[:lower:]')

## If the first argument is "command", run the rest of the arguments
## using todo.sh builtins.
## Else, run a actions script with the name of the command if it exists
## or fallback to using a builtin
if [ "$action" == command ]; then
	## Get rid of "command" from arguments list
	shift
	## Reset action to new first argument
	action=$(printf "%s\n" "$1" | tr '[:upper:]' '[:lower:]')
elif [ -d "$TODO_ACTIONS_DIR/$action" ] && [ -x "$TODO_ACTIONS_DIR/$action/$action" ]; then
	"$TODO_ACTIONS_DIR/$action/$action" "$@"
	exit $?
elif [ -d "$TODO_ACTIONS_DIR" ] && [ -x "$TODO_ACTIONS_DIR/$action" ]; then
	"$TODO_ACTIONS_DIR/$action" "$@"
	exit $?
fi

## Only run if $action isn't found in .todo.actions.d
case $action in
	"add" | "a")
		if [[ -z $2 && $TODOTXT_FORCE == 0 ]]; then
			echo -n "Add: "
			read -e -r input
		else
			[ -z "$2" ] && die "usage: $TODO_SH add \"TODO ITEM\""
			shift
			input=$*
		fi
		_addto "$TODO_FILE" "$input"
		;;

	"addm")
		if [[ -z $2 && $TODOTXT_FORCE == 0 ]]; then
			echo -n "Add: "
			read -e -r input
		else
			[ -z "$2" ] && die "usage: $TODO_SH addm \"TODO ITEM\""
			shift
			input=$*
		fi

		# Set Internal Field Seperator as newline so we can
		# loop across multiple lines
		SAVEIFS=$IFS
		IFS=$'\n'

		# Treat each line seperately
		for line in $input; do
			_addto "$TODO_FILE" "$line"
		done
		IFS=$SAVEIFS
		;;

	"append" | "app")
		errmsg="usage: $TODO_SH append ITEM# \"TEXT TO APPEND\""
		shift
		item=$1
		shift
		getTodo "$item"

		if [[ -z $1 && $TODOTXT_FORCE == 0 ]]; then
			echo -n "Append: "
			read -e -r input
		else
			input=$*
		fi
		case "$input" in
			[$SENTENCE_DELIMITERS]*) appendspace= ;;
			*) appendspace=" " ;;
		esac
		cleaninput "for sed"

		if sed -i.bak "${item} s|^.*|&${appendspace}${input}|" "$TODO_FILE"; then
			if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
				getNewtodo "$item"
				echo "$item $newtodo"
			fi
		else
			die "TODO: Error appending task $item."
		fi
		;;

	"archive")
		# defragment blank lines
		sed -i.bak -e '/./!d' "$TODO_FILE"
		# this could probably be rewritten with a single sed/awk call
		done=$(grep "^x " "$TODO_FILE")
		[ "$TODOTXT_VERBOSE" -gt 0 ] && [ -z "$TODOTXT_SILENT_ARCHIVE" ] && echo "$done"
		echo "$done" "$TODO_FILE" >> "$DONE_FILE"
		sed -i.bak '/^x /d' "$TODO_FILE"
		if [ "$TODOTXT_VERBOSE" -gt 0 ] && [ -z "$TODOTXT_SILENT_ARCHIVE" ]; then
			echo "TODO: $TODO_FILE archived."
		fi
		;;

	"depri" | "dp")
		errmsg="usage: $TODO_SH depri ITEM#[, ITEM#, ITEM#, ...]"
		shift
		[ $# -eq 0 ] && die "$errmsg"

		# Split multiple depri's, if comma separated change to whitespace separated
		# Loop the 'depri' function for each item
		for item in ${*//,/ }; do
			getTodo "$item"

			if [[ $todo == \(?\)\ * ]]; then
				sed -i.bak -e "${item}s/^(.) //" "$TODO_FILE"
				if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
					getNewtodo "$item"
					echo "$item $newtodo"
					echo "TODO: $item deprioritized."
				fi
			else
				echo "TODO: $item is not prioritized."
			fi
		done
		;;

	"do" | "done")
		errmsg="usage: $TODO_SH do ITEM#[, ITEM#, ITEM#, ...]"
		# shift so we get arguments to the do request
		shift
		[ "$#" -eq 0 ] && die "$errmsg"

		# Split multiple do's, if comma separated change to whitespace separated
		# Loop the 'do' function for each item
		[ "$TODOTXT_VERBOSE" -gt 0 ] && echo "items marked as done:"
		for item in ${*//,/ }; do
			getTodo "$item"

			# Check if this item has already been done
			if [ "${todo:0:2}" != "x " ]; then
				now=$(date '+%Y-%m-%d')
				# remove priority once item is done
				sed -i.bak "${item}s/^(.) //" "$TODO_FILE"
				sed -i.bak "${item}s|^|x $now |" "$TODO_FILE"
				if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
					getNewtodo "$item"
					echo "$item $newtodo"
				fi
			else
				echo "TODO: $item is already marked done."
			fi
		done

		# Recursively invoke the script to allow overriding of the archive
		# action.
		# TODO call archive with a bool flag that replaces SILENT_ARCHIVE variable
		"$TODO_FULL_SH" archive
		;;

	"list" | "ls")
		shift
		_list "$TODO_FILE" "$@"
		;;

	"listcon" | "lsc")
		shift
		listWordsWithSigil '@' "$@"
		;;

	"listproj" | "lsprj")
		shift
		listWordsWithSigil '+' "$@"
		;;

	"listpri" | "lsp")
		shift

		pri=$(printf "%s\n" "$1" | tr '[:lower:]' '[:upper:]' | grep -e '^[A-Z]$' -e '^[A-Z]-[A-Z]$') && shift || pri="A-Z"
		post_filter_command="${post_filter_command:-}${post_filter_command:+ | }grep '^ *[0-9]\+ ([${pri}]) '"
		_list "$TODO_FILE" "$@"
		;;

	uc)
		shift
		listTasksWithoutSigil "@" "$@"
		;;

	up)
		shift
		listTasksWithoutSigil "+" "$@"
		;;

	"prepend" | "prep")
		errmsg="usage: $TODO_SH prepend ITEM# \"TEXT TO PREPEND\""
		replaceOrPrepend 'prepend' "$@"
		;;

	"pri" | "p")
		item=$2
		newpri=$(printf "%s\n" "$3" | tr '[:lower:]' '[:upper:]')

		errmsg="usage: $TODO_SH pri ITEM# PRIORITY
note: PRIORITY must be anywhere from A to Z."

		[ "$#" -ne 3 ] && die "$errmsg"
		[[ $newpri == @([A-Z]) ]] || die "$errmsg"
		getTodo "$item"

		oldpri=
		if [[ $todo == \(?\)\ * ]]; then
			oldpri=${todo:1:1}
		fi

		if [ "$oldpri" != "$newpri" ]; then
			sed -i.bak -e "${item}s/^(.) //" -e "${item}s/^/($newpri) /" "$TODO_FILE"
		fi
		if [ "$TODOTXT_VERBOSE" -gt 0 ]; then
			getNewtodo "$item"
			echo "$item $newtodo"
			if [ "$oldpri" != "$newpri" ]; then
				if [ "$oldpri" ]; then
					echo "TODO: $item re-prioritized from ($oldpri) to ($newpri)."
				else
					echo "TODO: $item prioritized ($newpri)."
				fi
			fi
		fi
		if [ "$oldpri" = "$newpri" ]; then
			echo "TODO: $item already prioritized ($newpri)."
		fi
		;;

	*)
		die "invalid subcommand"
		;;
esac
