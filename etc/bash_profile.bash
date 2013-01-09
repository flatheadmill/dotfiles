#!/bin/bash

if [ -e ~/.bash_profile_before ]; then
  . ~/.bash_profile_before
fi

# Where are we?
src="${BASH_SOURCE[0]}"
dir="$( dirname "$src" )"
while [ -h "$src" ]
do 
  src="$(readlink "$src")"
  [[ $src != /* ]] && src="$dir/$source"
  dir="$( cd -P "$( dirname "$src"  )" && pwd )"
done
dir="$( cd -P "$( dirname "$src" )" && pwd )"

DOTFILES="$( dirname "$dir" )"

if [ -d /opt/bin ]; then
  PATH="/opt/bin:$PATH"
fi
if [ -d /opt/share/npm/bin ]; then
  PATH=/opt/bin:$PATH
fi

if ! { which node > /dev/null; } && [ -d /node ]; then
  echo "looking for node" 
fi

if [ -e ~/.usr/bin ]; then
  PATH=~/.usr/bin:$PATH
fi

export PATH

# Source all bash dotfiles.
for file in $(find "$DOTFILES/etc/bash_profile.d" -type f); do
  . "$file"
done
