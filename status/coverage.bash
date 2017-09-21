#!/bin/bash

pushd $(dirname ${BASH_SOURCE[0]}) > /dev/null
dir=$PWD
popd > /dev/null

make -s -f "$dir/Makefile"

jq -e '
.total | [
    .lines.pct, .statements.pct, .functions.pct, .branches.pct
] | add | . == 400
' < coverage/coverage-summary._json > /dev/null

if [ $? -ne 0 ]; then
    node_modules/.bin/istanbul report --format text    
    exit 1
fi
