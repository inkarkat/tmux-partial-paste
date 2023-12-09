#!/bin/bash source-this-script

# The last grep is required to remove non-digits from version such as "3.0a".
tmux_version="$(tmux -V | cut -d ' ' -f 2 | grep -Eo '[0-9\.]+')"
tmux-is-at-least() {
	if [[ $tmux_version == "$1" ]]; then
		return 0
	fi

	IFS='.' read -r -a tver <<< "$tmux_version"
	IFS='.' read -r -a wver <<< "$1"

	# fill empty fields in tver with zeros
	for ((i=${#tver[@]}; i<${#wver[@]}; i++)); do
		tver[i]=0
	done

	# fill empty fields in wver with zeros
	for ((i=${#wver[@]}; i<${#tver[@]}; i++)); do
		wver[i]=0
	done

	for ((i=0; i<${#tver[@]}; i++)); do
		if ((10#${tver[i]} < 10#${wver[i]})); then
			return 1
		elif ((10#${tver[i]} > 10#${wver[i]})); then
			return 0
		fi
	done
	return 0
}

if tmux-is-at-least 2.4; then
	bind_key_copy_mode() {
		local key="${1:?}"; shift
		tmux bind-key -T copy-mode-vi "$key" send-keys -X "$@"
		tmux bind-key -T copy-mode    "$key" send-keys -X "$@"
	}
else
	bind_key_copy_mode() {
		local key="${1:?}"; shift
		local tmux_command="${1:?}"; shift
		tmux_command="${tmux_command%-and-cancel}"
		tmux bind-key -t vi-copy    "$key" "$tmux_command" "$@"
		tmux bind-key -t emacs-copy "$key" "$tmux_command" "$@"
	}
fi

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

display_message() {
    local severity="${1:?}"; shift
    local message="${1:?}"; shift
    typeset -A durations=([info]=500 [error]=2000)

    local saved_display_time=$(get_tmux_option display-time 750)
    local display_duration=$(get_tmux_option "@partialpaste_${severity}_duration" ${durations["$severity"]} t)

    [ -z "$display_duration" ] || tmux set-option -gq display-time "$display_duration"

    [ "$display_duration" = 0 ] || tmux display-message "$message"

    tmux set-option -gq display-time "$saved_display_time"
}

keydef()
{
    local table="$1"; shift
    local key="$1"; shift
    [ "$key" ] || return 0

    tmux bind-key ${table:+-T "$table"} "$key" "$@"
}
