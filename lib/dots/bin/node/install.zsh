#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node install

  desctiption:

    Install Node.js dependencies relative to the \`dots\` library.
usage

(cd $DOTS_MOUNT/lib/dots/bin && npm install)
