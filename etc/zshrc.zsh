source $DOTFILES/etc/ohmy.zsh

for file in "$DOTFILES/etc/zprofile.d/"*; do
  . "$file"
done

unsetopt autopushd

fpath=( ~/.dotfiles/share/zsh/functions "${fpath[@]}" )
autoload -Uz fu

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
