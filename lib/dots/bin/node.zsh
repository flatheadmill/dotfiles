#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots hello
usage

perpetuate $0 "$@"
