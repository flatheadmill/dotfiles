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

export DOTFILES="$( dirname "$dir" )"

# Source all bash dotfiles.
for file in $(find "$DOTFILES/etc/bash_profile.d" -type f); do
  . "$file"
done
