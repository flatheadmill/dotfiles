# Give me a chance to figure it myself out before you redraw my screen.
setopt bash_autolist

# So much easier to see that the command failed and edit it.
unsetopt correct_all
unsetopt correct

# I don't want to automatically share history with other shells.
unsetopt share_history

# But, let's have the option by constantly appending to the history.
setopt inc_append_history
