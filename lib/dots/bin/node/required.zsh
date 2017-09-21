#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node required <scripts>

  desctiption:

    Generate coverage for one or more specific tests.
usage

IFS=''
for file in "$@"; do
    while read line; do
        match=()
        while [[ ! -z "$line" ]]; do
            if [[ "$line" =~ "(.*)require\('([^']+)'\)" ]] || [[ "$line" =~ '(.*)require\("([^"]+)"\)' ]]; then
                line="$match[1]"
                echo "$match[2]"
            else
                line=
            fi
        done
    done < $file
done
