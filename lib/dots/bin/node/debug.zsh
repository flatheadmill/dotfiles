#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node debug <script>

  desctiption:

    Launch \`node-inspector\` for the given script.
usage

function shutdown() {
    [ -z "$(jobs -p)" ] || kill "$(jobs -p)"
}

trap shutdown EXIT

script=$1

if [ -z "$script" ]; then
    usage 1
fi

node --debug-brk "$script" &

node_modules/.bin/node-inspector
