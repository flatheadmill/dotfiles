#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots fu add <name> <number>
  
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
number=$2
[ ! -z "$name" ] && [ ! -z "$number" ] || usage

export HISTFILE=~/.zsh_history 
fc -R
command=$(fc -l $number $number)
[[ $command =~ ' *[0-9]+ +(.*)' ]] && command=$match[1]
echo "$name $command" >> ~/git/.dotfiles-fu
