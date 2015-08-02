#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

package=$1

while read -r wanted latest; do
    echo "$wanted -> $latest"
    sed 's/\("'"$package"'":.*"\)'"$wanted"'/\1'"$latest"'/' package.json > package.json.tmp
    mv package.json.tmp package.json
    rm -rf node_modules
    npm install && npm test && \
        git commit -a -m 'Upgrade `'"$package"'` to '"$latest"'.'
done < <(npm outdated | tail +2 | awk -v package=$1 'package == $1 { print $3, $4 }')
