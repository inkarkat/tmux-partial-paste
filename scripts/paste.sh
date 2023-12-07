#!/bin/bash

inputFilespec="${1?}"; shift
typeset -a clipboardAccessCommand=("$@")
if [ -z "$inputFilespec" ]; then
    inputFilespec="$(mktemp --tmpdir "$(basename -- "$0")-XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/$(basename -- "$0").$$$RANDOM")"

    </dev/null "${clipboardAccessCommand[@]}" > "$inputFilespec" \
	|| tmux display-message "ERROR: Could not read from clipboard via ${clipboardAccessCommand[*]}"

    if [ -s "$inputFilespec" ]; then
	finally()
	{
	    if [ -s "$inputFilespec" ]; then
		cat -- "$inputFilespec"
	    else
		printf '\n'
	    fi \
		| "${clipboardAccessCommand[@]}" >/dev/null 2>&1 \
		    || tmux display-message "ERROR: Could not write to clipboard via ${clipboardAccessCommand[*]}"
	    [ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	}
	trap 'finally' EXIT
    else
	[ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	exec tmux display-message 'Empty clipboard'
    fi
elif [ ! -s "$inputFilespec" ]; then
    exec tmux display-message 'Nothing to paste'
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
	    tmux display-message 'Nothing to paste'
	    exit
	fi
	;;
    1)	tmux display-message 'Break in input';;
    2)	tmux display-message 'Input fully pasted';;
    *)	tmux display-message "Unexpected exit status $?";;
esac

tmux set-buffer -b partialpaste "$firstLine" \; \
    paste-buffer -b partialpaste
