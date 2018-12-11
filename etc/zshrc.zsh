source $DOTFILES/etc/ohmy.zsh

for file in "$DOTFILES/etc/zprofile.d/"*; do
  . "$file"
done

unsetopt autopushd

fpath=( ~/.dotfiles/share/zsh/functions "${fpath[@]}" )
autoload -Uz fu
