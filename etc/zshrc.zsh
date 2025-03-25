# +-------------+
# | Environment |
# +-------------+

export EDITOR=vim                # Set the default editor.
export HISTSIZE=100000           # As much history in memory as possible.
export SAVEHIST=100000           # As much history saved to disk as is possible.
export HISTFILESIZE=100000
export HISTFILE=~/.zsh_history

# +-----------------+
# | History Options |
# +-----------------+

# Want all my `tmux` sessions to record history for posterity, but we don't want
# them loading up each others commands because that gets confusing.

setopt HIST_EXPIRE_DUPS_FIRST   # Delete duplicates before deleting the tail of history.
setopt HIST_FIND_NO_DUPS        # Skip a duplicate when performing a reverse search.
setopt HIST_IGNORE_SPACE        # Do not record command lines where leading character is a space.
setopt HIST_VERIFY              # Don't just execute the command, load it into the line buffer.
setopt INC_APPEND_HISTORY       # Incrementally append history, allows us to feed history from many `tmux` panes.

setopt ALWAYS_TO_END            # Move cursor to end of completed word. TODO Disable and observe.
setopt BASH_AUTO_LIST           # Auto list on a double tab.
setopt COMBINING_CHARS          # TODO Possibly requires a test before setting.
setopt COMPLETE_IN_WORD         # This will expand `fbar` to `foobar` when the cursor is at the end of the word.
setopt NO_FLOW_CONTROL          # Something to do with silencing the terminal. TODO Enable and observe and research.
setopt INTERACTIVE              # Insist that this is an interactive shell.
setopt INTERACTIVE_COMMENTS     # Allow comments even in interactive shells.
setopt LONG_LIST_JOBS           # Print job notifications in the long format by default.
setopt MONITOR                  # Allow job control. Set by default in interactive shells.
setopt PROMPT_SUBST             # Perform parameter expansion, command substitution, and arithmetic expansion in prompts.
                                # TODO ^ Do I need this when I'm using `minimal.zsh`?
setopt PUSHD_IGNORE_DUPS        # Don’t push multiple copies of the same directory onto the directory stack.
setopt PUSHD_MINUS              # Transpose the meanings of `+` and `-` when referencing the stack.
unsetopt BEEP                   # Perhaps someday I'll want a visual bell, but the sound is annoying.

unsetopt extendedglob           # Makes `git reset --hard HEAD^` annoying, but maybe it should be.

# +------+
# | PATH |
# +------+

function {
    typeset part parts=(
        /usr/local/bin
        # Homebrew
        ~/.usr/bin
        ~/go/bin
        ~/.cargo/bin
        ~/.asdf/shims
    )
    print here
    for part in "${(@)parts}"; do
        if [[ -d $part ]] && [[ ":${PATH}:" != *:$part:* ]]; then
            export PATH=$part:$PATH
        fi
    done
}

# +-----------------+
# | TMUX SSH socket |
# +-----------------+

if [ -n "$TMUX" ]; then
  function refresh {
    typeset ssh_auth_sock=$(tmux show-environment | grep "^SSH_AUTH_SOCK")
    if [[ -n $ssh_auth_sock ]]; then
        export "$ssh_auth_sock"
    fi
  }
else
  function refresh {}
fi

function preexec {
    refresh
}

# +-------------+
# | Completions |
# +-------------+

_comp_options+=(globdots)       # With hidden files.
# TODO Why is this one special? Can't be right.
aws_zsh_completer=$(which aws_zsh_completer.sh)
if [[ $? -eq 0 ]]; then
    source $aws_zsh_completer
fi

# Completions I've gathered along the way.
fpath=( ~/.dotfiles/completions $fpath )

# TODO Where do I put my Unix completions?
command -v brew && fpath=( "$(brew --prefix)/share/zsh/site-functions" "${fpath[@]}" )

# Dubious.
fpath=( ~/.dotfiles/share/zsh/functions "${fpath[@]}" )
if [[ -d ~/.usr/share/zsh/functions ]]; then
    fpath=( ~/.usr/share/zsh/functions "${fpath[@]}" )
fi

# Initialize completions.
autoload -U compinit
compinit

# Completions for `delta`.
command -v delta > /dev/null && compdef _gnu_generic delta   

# Outgoing?
autoload -Uz fu

MNML_PROMPT=(mnml_pyenv mnml_status mnml_keymap)
MNML_RPROMPT=('mnml_cwd 2 0' mnml_git mnml_ssh)
source $HOME/.dotfiles/vendor/minimal.zsh

# +---------------------+
# | Prompt Interceptors |
# +---------------------+

# Reset the `SSH_AUTH_SOCK` before each command. Could also symlink it on
# startup, but this works too.
#
# https://www.babushk.in/posts/renew-environment-tmux.html

#

my_precmd() {
  vcs_info
  psvar[1]=$vcs_info_msg_0_
  if [[ -n ${psvar[1]} ]]; then
    psvar[1]=" (${psvar[1]})"
  fi
}


bindkey -v
bindkey '^R' history-incremental-pattern-search-backward 

mnml_ssh() {
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        typeset hostname=$(hostname -f) parts=( "${(a@s/./)hostname}" )
        if (( ${#parts[@]} == 7 )); then
            printf '%b' "${parts[1][1]}.${parts[2]}.${parts[6]}.${parts[7]}"
        else
            printf '%b' "${parts[1]}"
        fi
    fi
}

function airbrush {
    typeset histsize=$HISTSIZE
    if [[ -n "$1" ]]; then
        history | grep -e "$1"
        HISTSIZE=0
        LC_ALL=C sed -i -e '/'"$1"'/d' "$HISTFILE"
        HISTSIZE=$histsize
        fc -R
    fi
}

autoload edit-command-line; zle -N edit-command-line; 
bindkey -M vicmd v edit-command-line
