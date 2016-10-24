#!/bin/bash

signal=$1

[ ! -e ~/.usr/tmp/tmux.run.pid ] && exit 0

rm -f ~/.usr/tmp/tmux.run.run

pid=$(<~/.usr/tmp/tmux.run.pid)
ppid=$(ps axo pid,ppid | awk -v pid=$pid '$1 == pid { print $2 }')

while read -r line; do
    kill -$signal $line > /dev/null 2>&1
done < <(ps xao pid,pgid,command | \
        awk -v pid=$pid \
            -v ppid=$ppid \
            'pid != $1 && ppid != $1 && ppid == $2 { print $1 }')

exit
