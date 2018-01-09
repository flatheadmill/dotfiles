#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git issue open [number]

  options:

    -h,--help                   display this message

usage

zparseopts -D -- -help=usage h=usage

[ -z "$usage" ] || usage

issue="$1"
open $(dots git issue get -u "$issue")
