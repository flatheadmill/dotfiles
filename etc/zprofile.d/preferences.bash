# Give me a chance to figure it myself out before you redraw my screen.
setopt bash_autolist

# I want vi key bindings where ever I can get them. It appears that both of the
# following are required for `zsh`.
set -o vi
bindkey -v

# http://unix.stackexchange.com/questions/44115/how-do-i-perform-a-reverse-history-search-in-zshs-vi-mode
# https://bbs.archlinux.org/viewtopic.php?id=52173

# I still want to be able to reverse search with ctrl-R.
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward
