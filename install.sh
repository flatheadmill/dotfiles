#!/bin/bash

# Installation of ~bigeasy/dotfiles. At first I thought I'd use a Makefile, but
# I might want to administer a server where build tools are not installed.
#
# Oh, no wait. I can just install make, without other build tools.
#
# My approach is to treat my environment as a the combination of my editor and
# shell of choice plus a prefered scripting language. My dotfiles do not
# attempt to make one UNIX like every other.
#
# My preferred scripting language has been bash, because it's everywhere, but
# I'm drifting over to Node.js, so that a Node.js is going to be something I'll
# want to install on every machine I work with.
#
# Looks as though I've decided to make a `curl | bash` installer.

function abend () {
  echo "fatal: $1" 1>&2
  exit 1
}

git_version=$(git --version 2>/dev/null)
if [ $? -ne 0 ]; then
  abend "git is not installed"
fi
git_version="${git_version#git version }"
if ! { [[  "$git_version" == 1.8.* ]] || [[ "$git_version" == 1.7.1[0-9].* ]]; }; then
  abend "git is at version $git_version but must be at least 1.7.10"
fi

DOTFILES="$HOME/.dotfiles"

if ! [ -e "$HOME/.dotfiles" ]; then
  git clone git://github.com/bigeasy/dotfiles.git "$DOTFILES"
fi

rsync -a "$DOTFILES/home" "$HOME"
