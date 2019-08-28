#!/usr/bin/env zsh

# Simple indempotent instllation.
#
# First, replace all rc files with a template file and over write it. Do this
# instead of trying to add a source file line to the default rc file. The
# default file is a sandwich, machine specific before rc, dotfiles rc, machine
# specific after rc. The before and after are in dotfiles/rc/before and
# dotfiles/rc/after. You simply touch them if they do not already exist. Let's
# start with just after, since you can undo most things in rc files.
#
# When installing these sandwiches, check to see if the existing file is already
# a sandwich, if not, move it to an outgoing home directly. Let the user know
# that a file was to be overwitten so we moved it out of the way.

function abend () {
  echo "fatal: $1" 1>&2
  exit 1
}

git_version=$(git --version 2>/dev/null)
if [ $? -ne 0 ]; then
  abend "git is not installed"
fi
git_version="${git_version#git version }"
if ! { [[ "$git_version" == 2.* ]] || [[  "$git_version" == 1.[8-9].* ]] || [[ "$git_version" == 1.7.1[0-9].* ]]; }; then
  abend "git is at version $git_version but must be at least 1.7.10"
fi

if [ $(basename $SHELL) != "zsh" ]; then
  if [[ "$1" = "sudo" ]]; then
    sudo chsh -s $(which zsh) $USER
  else
    if [[ "$OSTYPE" = "linux-gnu" ]]; then
      abend "you need to: sudo usermod --shell $(which zsh) $USER"
    else
      abend "you need to: sudo chsh -s $(which zsh) $USER"
    fi
  fi
fi

if ! [ -e "$HOME/.oh-my-zsh" ]; then
  curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
fi

if ! [[ -e "$HOME/.vim/autoload/plug.vim" ]]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if ! [ -e "$HOME/.dotfiles" ]; then
  git clone --recursive git://github.com/bigeasy/dotfiles.git "$HOME/.dotfiles"
fi

stamp=$(date +'%F-%T' | sed 's/:/-/g')

function create_rc () {
    local home_file=$1 skel_file=$2
    local home_path="$HOME/$home_file"
    local skel_path="$HOME/.dotfiles/skel/$skel_file"
    if [ -e "$home_path" ] && ! diff "$home_path" "$skel_path" > /dev/null; then
        mkdir -p "$HOME/.dotfiles/replaced/$stamp"
        mv "$home_path" "$HOME/.dotfiles/replaced/$stamp/$skel_file"
    fi
    cp "$skel_path" "$home_path"
    local local_path="$HOME/.dotfiles/rc/$skel_file"
    if [ ! -e "$local_path" ]; then
        mkdir -p "$HOME/.dotfiles/rc"
        touch "$local_path"
    fi
}

create_rc .zshenv zshenv.zsh
create_rc .zprofile zprofile.zsh
create_rc .zshrc zshrc.zsh
create_rc .tmux.conf tmux.conf
create_rc .gitconfig gitconfig
create_rc .vimrc vimrc

# Tired of wrestling with Unicode.
cd ~/.oh-my-zsh && patch -p 1 < ~/.dotfiles/share/terminalparty.patch

if [ -e "$HOME/.dotfiles/replaced/$stamp/$skel_file" ]; then
cat <<EOF
Existing configuration files where replaced. The replaced files have been
moved to:

  ~/.dotfiles/replaced/$stamp

Fish out anything you want to keep and move it to the file with the same name in
the directory:

  ~/.dotfiles/rc

This is where your machine specific settings should be kept.
EOF
fi
