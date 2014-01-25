#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git reissue
usage

subject="$(git log -n 1 --pretty=format:'%s')" 

number=$(dots git issue "$subject")
body="$(git log -n 1 --pretty=format:'%B')" 

git commit --amend -F - << BODY
$body

Closes #100.
BODY
