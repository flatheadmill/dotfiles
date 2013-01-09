# I want vi key bindings where ever I can get them.
bindkey -v

# http://unix.stackexchange.com/questions/44115/how-do-i-perform-a-reverse-history-search-in-zshs-vi-mode
# https://bbs.archlinux.org/viewtopic.php?id=52173

# I still want to be able to reverse search with ctrl-R.
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward
