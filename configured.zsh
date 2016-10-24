if [ -e ~/.dotfiles/install.zsh ]; then
    zsh ~/.dotfiles/install.zsh
else
    curl https://raw.githubusercontent.com/bigeasy/dotfiles/master/install.zsh | zsh
fi

git config --file ~/.dotfiles/rc/gitconfig --add user.name 'Alan Gutierrez'
git config --file ~/.dotfiles/rc/gitconfig --add user.email 'alan@prettyrobots.com'
git config --file ~/.dotfiles/rc/gitconfig --add github.user 'bigeasy'
