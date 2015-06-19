source $DOTFILES/etc/ohmy.zsh

for file in "$DOTFILES/etc/zprofile.d/"*; do
  . "$file"
done
