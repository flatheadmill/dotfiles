# Where are we?
src="$0"
dir="$( dirname "$src" )"
while [ -h "$src" ]
do 
  src="$(readlink "$src")"
  [[ $src != /* ]] && src="$dir/$source"
  dir="$( cd -P "$( dirname "$src"  )" && pwd )"
done

dir="$( cd -P "$( dirname "$src" )" && pwd )"

DOTFILES="$( dirname "$dir" )"
PATH="$DOTFILES/bin":$PATH

if [ -d /opt/bin ]; then
  PATH="/opt/bin:$PATH"
fi

if [ -d $HOME/.usr/share/npm/bin ]; then
  PATH=$HOME/.usr/share/npm/bin:$PATH
fi

if [ -e ~/.usr/bin ]; then
  PATH=~/.usr/bin:$PATH
fi

if [ -d "$HOME/node_modules/.bin" ]; then
  PATH=$PATH:$HOME/node_modules/.bin
fi

export PATH DOTFILES
