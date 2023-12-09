# Tmux partial paste

_Tmux plugin for pasting line by line._

This plugin offers pasting (and consuming) only the first line of a file / the system clipboard.
If you have a series of commands, or several data values, you can paste them one by one until the input source is exhausted.

Lines with line continuation (i.e. a trailing backslash) are pasted all at once; the line continuation is kept.

### Key bindings

- <kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>l</kbd> <kbd>]</kbd> <br>
  Paste the first line of the input file and remove that line from the file.
- <kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>l</kbd> <kbd>Ctrl</kbd>+<kbd>]</kbd> <br>
  Paste the first line of the input file and <kbd>Enter</kbd>, and remove that
  line from the file.
  The next paste will paste the following line.
  The next built-in paste (prefix + ]) will repeat the paste of that line.
- <kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>l</kbd> <kbd>v</kbd> <br>
  Paste the first line of the system clipboard and remove that line from it.
- <kbd>prefix</kbd> <kbd>Ctrl</kbd>+<kbd>l</kbd> <kbd>Ctrl</kbd>+<kbd>v</kbd> <br>
  Paste the first line of the system clipboard and <kbd>Enter</kbd>, and remove
  that line from it.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'inkarkat/tmux-partial-paste'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to use the plugin.

### Manual Installation

Clone the repo:

    $ git clone https://github.com/inkarkat/tmux-partial-paste ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/named-registers.tmux

Reload tmux environment with: `$ tmux source-file ~/.tmux.conf`. You should now be able to use the plugin.

### Configuration

- `@partialpaste_inputfile` &mdash; filespec (default `~/.tmux-partial-paste`) where the input is taken from.
- `@partialpaste_inputfile_incomplete_key` &mdash; tmux key for pasting from the input file
- `@partialpaste_inputfile_entered_key` &mdash; tmux key for pasting from the input file with appended Enter
- `@partialpaste_clipboard_command` &mdash; command-line to read the clipboard contents from / write to.
- `@partialpaste_clipboard_incomplete_key` &mdash; tmux key for pasting from the system clipboard
- `@partialpaste_clipboard_entered_key` &mdash; tmux key for pasting from the system clipboard with appended Enter
- `@partialpaste_table` &mdash; tmux client key table for the above keys; you can use this to define a sequence of keys to trigger the command
- `@partialpaste_display_duration` &mdash; duration in milliseconds for the plugin's status messages; use 0 to completely suppress those

### License

[GPLv3](LICENSE)
