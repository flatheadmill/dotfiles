#!/usr/bin/env zsh

while read line; do
  [ -h "node_modules/$line" ] && rm "node_modules/$line"
done <<(dots node dependencies)

npm install
