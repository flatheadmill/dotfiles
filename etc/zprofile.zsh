if [ -e ~/.bash_profile_before ]; then
  . ~/.bash_profile_before
fi

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

PATH=~/.dotfiles/bin:$PATH

if [ -d /opt/bin ]; then
  PATH="/opt/bin:$PATH"
fi

if [ -d /Users/alan/.usr/share/npm/bin ]; then
  PATH=/Users/alan/.usr/share/npm/bin:$PATH
fi

if [ -e ~/.usr/bin ]; then
  PATH=~/.usr/bin:$PATH
fi

if ! { which node > /dev/null 2>&1; } && [ -d /node ]; then
  echo "looking for node" 
fi

export PATH

source $DOTFILES/etc/ohmy.zsh

ZSH_CUSTOM=$DOTFILES/etc/zprofile.d
unset DOTFILES

# Source all bash dotfiles.
#for file in $DOTFILES/etc/zprofile.d/*; do
#  . "$file"
#done
