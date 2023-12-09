#!/bin/bash

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
    run-shell "${quotedScriptDir}/paste.sh --file $quotedInputFilespec"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_inputfile_entered_key" \
    run-shell "${quotedScriptDir}/paste.sh --enter --file $quotedInputFilespec"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_clipboard_incomplete_key" \
    run-shell "${quotedScriptDir}/paste.sh --clipboard $clipboardAccessCommand"
keydef "${partialpaste_table:+partialpaste}" "$partialpaste_clipboard_entered_key" \
    run-shell "${quotedScriptDir}/paste.sh --enter --clipboard $clipboardAccessCommand"
