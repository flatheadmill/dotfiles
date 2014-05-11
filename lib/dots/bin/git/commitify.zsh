#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git commitify <options>
  
  options:
    
    -h,--help                   display this message
    -m,--message   <string>     commit message

usage

zparseopts -D -- -help=usage h=usage \
                 -message:=message m:=message

echo "$@"
[ -z "$usage[1]" ] || usage
[ -z "$message[2]" ] && usage

set -e

git add .
git commit --dry-run
issue=$(dots git issue create -m able -l enhancement "$message[2]")
git commit -m "$(dots git issue get $issue)"$'\n\nCloses #'$issue'.'
(dots git release > release.md.bak) && mv release.md.bak release.md
git add release.md
git commit --amend -a --no-edit
