#!/bin/bash

readonly scriptDir="$([ "${BASH_SOURCE[0]}" ] && dirname -- "${BASH_SOURCE[0]}" || exit 3)"
[ -d "$scriptDir" ] || { echo >&2 'ERROR: Cannot determine script directory!'; exit 3; }
source "${scriptDir}/helpers.sh"

inputFilespec=
typeset -a clipboardAccessCommand=("$@")
typeset additionalPasteCommand=()
while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)	shift; printUsage "$0"; exit 0;;
	--enter)	shift; additionalPasteCommand=(\; send-key Enter);;
	--file)		shift; inputFilespec="${1?}"; shift;;
	--clipboard)	shift; clipboardAccessCommand=("$@"); set --; break;;
	-*)		{ echo "ERROR: Unknown option \"$1\"!"; echo; printUsage "$0"; } >&2; exit 2;;
	*)		break;;
    esac
done

inputWhat="$inputFilespec"
if [ -z "$inputFilespec" ]; then
    inputWhat='clipboard'
    inputFilespec="$(mktemp --tmpdir "$(basename -- "$0")-XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/$(basename -- "$0").$$$RANDOM")"

    </dev/null "${clipboardAccessCommand[@]}" > "$inputFilespec" \
	|| fail "could not read from $inputWhat via ${clipboardAccessCommand[*]}"

    if [ -s "$inputFilespec" ]; then
	finally()
	{
	    if [ -s "$inputFilespec" ]; then
		cat -- "$inputFilespec"
	    else
		printf '\n'
	    fi \
		| "${clipboardAccessCommand[@]}" >/dev/null 2>&1 \
		    || fail "could not write to $inputWhat via ${clipboardAccessCommand[*]}"
	    [ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	}
	trap 'finally' EXIT
    else
	[ "${DEBUG:-}" ] || rm -f -- "$inputFilespec" 2>/dev/null
	display_message error "Empty ${inputWhat}"
	exit 0
    fi
elif [ ! -s "$inputFilespec" ]; then
    display_message error "Nothing in $inputWhat"
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
	    display_message error "Nothing in $inputWhat"
	    exit
	fi
	;;
    1)	display_message info 'Break in input';;
    2)	display_message info "$inputWhat fully pasted";;
    *)	fail "encountered an unexpected exit status $?";;
esac

tmux set-buffer -b partialpaste "$firstLine" \; \
    paste-buffer -b partialpaste \
    "${additionalPasteCommand[@]}"
