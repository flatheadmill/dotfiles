# I still want to be able to reverse search with ctrl-R even though I've opted
# for vi mode.
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward
