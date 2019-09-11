#!/usr/bin/env zsh

set -e

zmodload zsh/pcre
setopt REMATCH_PCRE

repo=$(git config --get remote.origin.url)

[[ $repo =~ 'git://github\.com/(.*)\.git' ]] || \
    { print -u2 "error: not a GitHub repository" && exit 1; }

print "https://github.com/${match[1]}"
