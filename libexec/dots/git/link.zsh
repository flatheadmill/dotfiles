#!/usr/bin/env zsh

if [ $# -eq 0 ]; then
  set -- $(cd .. && pwd)
fi

while read line; do
  for dir in "$@"; do 
    if [ -d "$dir/$line" ]; then
      [ -e "node_modules/$line" ] && rm -r "node_modules/$line"
      ln -s "$dir/$line" "node_modules/$line"
    fi
  done
done <<(dots node dependencies)
