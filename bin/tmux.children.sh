#!/bin/bash

pid=$1 ppid=$2 setpgrp=$3

ps axo pid,pgid | \
    awk -v pid=$pid -v ppid=$ppid -v setpgrp=$setpgrp \
    'pid != $1 && ppid != $1 && setpgrp != $1 && ppid == $2 { print $1 }' | xargs echo
