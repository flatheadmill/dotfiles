#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git [command]
usage

("$@" > ~/.usr/tmp/tmux.run.log 2>&1 ) &
