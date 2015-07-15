#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots fu run [name] [arguments..]
  
  options:
    
    -h,--help                   display this message

  description:

    Save a command from history as a quick and dirty program. Creates a program
    that named $name from the command in the history $number.
usage

zparseopts -D -- -help=usage h=usage

[ -z "$usage" ] || usage
name=$1
shift
[ ! -z "$name" ] || usage

while read -r line; do
    label=${line%% *}
    expression=${line#* }
    if [ "$label" = "$name" ]; then
        eval $expression
        break
    fi
done < ~/.dotfiles/fu
