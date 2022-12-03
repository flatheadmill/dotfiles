set -e

if [ -e ~/.dotfiles/install.zsh ]; then
    zsh ~/.dotfiles/install.zsh "$@"
else
    curl https://raw.githubusercontent.com/flatheadmill/dotfiles/master/install.zsh | zsh -s "$@"
fi

git config --file ~/.dotfiles/rc/gitconfig --add user.name 'Alan Gutierrez'
git config --file ~/.dotfiles/rc/gitconfig --add user.email 'alan@prettyrobots.com'
git config --file ~/.dotfiles/rc/gitconfig --add github.user 'bigeasy'
