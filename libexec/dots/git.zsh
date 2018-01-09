#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git [command]
usage

dots util perpetuate $0 "$@"
