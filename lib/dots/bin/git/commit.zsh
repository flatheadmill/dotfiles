#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git commit <options>
  
  options:
    
    -h,--help                   display this message
    -i,--issue   <string>       issue to use for commit message

usage

zparseopts -D -- -help=usage h=usage \
                 -issue:=issue i:=issue

[ -z "$usage" ] || usage
[ -z "$issue" ] && usage

issue=issue[2]
git add .
git commit -m "$(dots git issue get $issue)"$'\n\nCloses #'$issue'.'
(dots git release > release.md.bak) && mv release.md.bak release.md
git add release.md
git commit --amend -a --no-edit
