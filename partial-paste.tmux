#!/bin/bash

fail() {
    tmux display-message "ERROR: tmux-partial-paste ${1:-encountered an unspecified problem.}"
    exit 3
}

get_tmux_option() {
	local option="${1:?}"; shift
	local default_value="${1?}"; shift
	local isAllowEmpty="$1"; shift
	local option_value
	if ! option_value="$(tmux show-option -gv "$option" 2>/dev/null)"; then
	    # tmux fails if the user option is unset.
	    echo "$default_value"
	elif [ -z "$option_value" ] && [ "$isAllowEmpty" ]; then
	    # XXX: tmux 3.0a returns an empty string for a user option that is unset, but does not fail any longer.
	    tmux show-options -g | grep --quiet --fixed-strings --line-regexp "$option " && return
	    printf %s "$default_value"
	else
	    printf %s "${option_value:-$default_value}"
	fi
}

keydef()
{
    local table="$1"; shift
    local key="$1"; shift
    [ "$key" ] || return 0

    tmux bind-key ${table:+-T "$table"} "$key" "$@"
}

readonly projectDir="$([ "${BASH_SOURCE[0]}" ] && cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$projectDir" ] || fail 'cannot determine script directory!'
printf -v quotedScriptDir '%q' "${projectDir}/scripts"

# shellcheck source=./scripts/helpers.sh
source "${projectDir}/scripts/helpers.sh"
tmux-is-at-least 2.1 || exit 0

printf -v quotedInputFilespec %q "$(get_tmux_option '@partialpaste_inputfile' ~/.tmux-partial-paste)"
clipboardAccessCommand="$(get_tmux_option '@partialpaste_clipboard_command' 'xsel --clipboard')"

partialpaste_table="$(get_tmux_option '@partialpaste_table' 'C-l' t)"
partialpaste_inputfile_incomplete_key="$(get_tmux_option '@partialpaste_inputfile_incomplete_key' ']' t)"
partialpaste_inputfile_entered_key="$(get_tmux_option '@partialpaste_inputfile_entered_key' 'C-]' t)"
partialpaste_clipboard_incomplete_key="$(get_tmux_option '@partialpaste_clipboard_incomplete_key' 'v' t)"
partialpaste_clipboard_entered_key="$(get_tmux_option '@partialpaste_clipboard_entered_key' 'C-v' t)"

if [ -n "$partialpaste_table" ]; then
    tmux bind-key "$partialpaste_table" switch-client -T partialpaste
fi

keydef "${partialpaste_table:+partialpaste}" "$partialpaste_inputfile_incomplete_key" \
    run-shell "${quotedScriptDir}/paste.sh '' $quotedInputFilespec"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_inputfile_entered_key" \
    run-shell "${quotedScriptDir}/paste.sh t $quotedInputFilespec"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_clipboard_incomplete_key" \
    run-shell "${quotedScriptDir}/paste.sh '' '' $clipboardAccessCommand"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_clipboard_entered_key" \
    run-shell "${quotedScriptDir}/paste.sh t '' $clipboardAccessCommand"
