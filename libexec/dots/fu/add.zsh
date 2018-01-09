#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots fu add <name>
  
  options:
    
    -h,--help                   display this message
    -i,--issue   <string>       issue to use for commit message

  description:

    Save a command from history as a quick and dirty program. Creates a program
    that named $name from the command in the history $number.
usage

zparseopts -D -- -help=usage h=usage \
                 -issue:=issue i:=issue

[ -z "$usage" ] || usage
name=$1
[ ! -z "$name" ] || usage

command=`head -n 1 | sed 's/ *[0-9][0-9]* *//'`

echo "$name $command" >> ~/git/.dotfiles-fu
