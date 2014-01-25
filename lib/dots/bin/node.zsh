#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots hello
usage

dots perpetuate $0 "$@"
