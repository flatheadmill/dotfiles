## Completions.

# TODO Why is this one special?
aws_zsh_completer=$(which aws_zsh_completer.sh)
if [[ $? -eq 0 ]]; then
    source $aws_zsh_completer
fi

if type brew &>/dev/null
then
    fpath=( "$(brew --prefix)/share/zsh/site-functions" "${fpath[@]}" )
fi

fpath=( ~/.dotfiles/share/zsh/functions "${fpath[@]}" )
if [[ -d ~/.usr/share/zsh/functions ]]; then
    fpath=( ~/.usr/share/zsh/functions "${fpath[@]}" )
fi

autoload -Uz fu

source $HOME/.dotfiles/vendor/minimal.zsh

# Reset the `SSH_AUTH_SOCK` before each command. Could also symlink it on
# startup, but this works too.
# https://www.babushk.in/posts/renew-environment-tmux.html
if [ -n "$TMUX" ]; then
  function refresh {
    local ssh_auth_sock="$(tmux show-environment | grep "^SSH_AUTH_SOCK")"
    if [[ -n "$ssh_auth_sock" ]]; then
        export "$ssh_auth_sock"
    fi
  }
else
  function refresh {}
fi

function preexec {
    refresh
}

my_precmd() {
  vcs_info
  psvar[1]=$vcs_info_msg_0_
  if [[ -n ${psvar[1]} ]]; then
    psvar[1]=" (${psvar[1]})"
  fi
}

export HISTSIZE=1000000000
export HISTFILESIZE=1000000000
#
#setopt INC_APPEND_HISTORY

bindkey '^R' history-incremental-pattern-search-backward 

mnml_ssh() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        local hostname=$(hostname -f)
        typeset -a parts=( "${(a@s/./)hostname}" )
        if (( ${#parts[@]} == 7 )); then
            printf '%b' "${parts[1][1]}.${parts[2]}.${parts[6]}.${parts[7]}"
        else
            printf '%b' "${parts[1]}"
        fi
    fi
}

export EDITOR=vim
