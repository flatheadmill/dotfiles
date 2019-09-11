#!/usr/bin/env zsh

set -e

#zmodload zsh/pcre
#setopt REMATCH_PCRE

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

# https://gist.github.com/earthgecko/3089509
separator=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | fold -w ${1:-32} | head -n 1)

dir=$(pwd)
( \
    { cd "$tmp" && git -C "$dir" log --format=%B$separator | \
    csplit -s -k -n 5 - "/$separator/" '{99999}'; } 2> /dev/null || true; \
)

echo "----------"
for file in $( cd "$tmp" && echo xx*(on) ); do
    if  head -n 2 "$tmp/$file" | grep 'Release' > /dev/null; then
    #if head -n 1 "$tmp/$file" | grep 'Release'; then
        break
    else
        cat "$tmp/$file"
    fi
done
