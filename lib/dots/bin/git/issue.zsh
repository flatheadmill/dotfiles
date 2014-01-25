#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git issue [command]
usage

dots util perpetuate $0 "$@"
