#!/bin/bash

for regex in DELIMITER PARAMETER STRING; do
    compiled=$({ tr -d '\n' | tr -d ' '; } <  $regex.regex)
    compiled=$(echo "$compiled" | sed 's/\\/\\\\/g')
    compiled=$(echo "$compiled" | sed 's/\//\\\//g')
    sed -i.bak 's/var '$regex' = .*/var '$regex' = '"$compiled"'/' synonymous.js
done
