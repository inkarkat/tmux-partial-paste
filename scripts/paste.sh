#!/bin/bash

readonly scriptDir="$([ "${BASH_SOURCE[0]}" ] && dirname -- "${BASH_SOURCE[0]}" || exit 3)"
[ -d "$scriptDir" ] || { echo >&2 'ERROR: Cannot determine script directory!'; exit 3; }
source "${scriptDir}/helpers.sh"

typeset additionalPasteCommand=()
[ "${1?}" ] && additionalPasteCommand=(\; send-key Enter); shift
inputFilespec="${1?}"; shift
typeset -a clipboardAccessCommand=("$@")

if [ -z "$inputFilespec" ]; then
    inputFilespec="$(mktemp --tmpdir "$(basename -- "$0")-XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/$(basename -- "$0").$$$RANDOM")"

    </dev/null "${clipboardAccessCommand[@]}" > "$inputFilespec" \
	|| fail "could not read from clipboard via ${clipboardAccessCommand[*]}"

    if [ -s "$inputFilespec" ]; then
	finally()
	{
	    if [ -s "$inputFilespec" ]; then
		cat -- "$inputFilespec"
	    else
		printf '\n'
	    fi \
		| "${clipboardAccessCommand[@]}" >/dev/null 2>&1 \
		    || fail "could not write to clipboard via ${clipboardAccessCommand[*]}"
	    [ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	}
	trap 'finally' EXIT
    else
	[ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	display_message 'Empty clipboard'
	exit 0
    fi
elif [ ! -s "$inputFilespec" ]; then
    display_message 'Nothing to paste'
    exit 0
fi

firstLine="$(sed -i -e '
1{
    /^$/b eatLeadingEmpty
    b extractFirst
}
${
    # Check flag, and indicate break in input with exit status.
    x
    /./{ x; q 1; }
    x
}
b

:eatLeadingEmpty
N; s/^\n//
/^$/b eatLeadingEmpty
:extractFirst
/\\$/ {
    N
    b extractFirst
}
w /dev/stdout
$Q 2	# No more input lines at all.
s/.*//
N; s/^\n//
:checkRemainderOnlyEmpty
/^$/ {
    H	    # Flag: We have encountered an empty line; this is a break in input (or no more input at all).
    $Q 2    # It is no input at all; just empty lines.
    N; s/^\n//
    b checkRemainderOnlyEmpty
}
' -- "$inputFilespec")"
case $? in
    0)	if [ -z "$firstLine" ]; then
	    # Input consisted of just empty line(s).
	    display_message 'Nothing to paste'
	    exit
	fi
	;;
    1)	display_message 'Break in input';;
    2)	display_message 'Input fully pasted';;
    *)	fail "encountered an unexpected exit status $?";;
esac

tmux set-buffer -b partialpaste "$firstLine" \; \
    paste-buffer -b partialpaste \
    "${additionalPasteCommand[@]}"
