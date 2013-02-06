# I still want to be able to reverse search with ctrl-R even though I've opted
# for vi mode.
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward

# Use `v` to launch editor.
# http://stackoverflow.com/questions/890620/unable-to-have-bash-like-c-x-e-in-zsh
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line
