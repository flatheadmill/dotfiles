#!/usr/bin/env zsh

# TODO Switches to allow development and canary.

source $dots <<- usage
  usage: dots node outdated

  desctiption:

    Determine which modules are outdated in the current project.
usage

set -e

zparseopts -D -a o_dist d+: -dist+:

if [[ ${#o_dist} -eq 0 ]]; then
    o_dist=(-d latest)
fi

typeset -A dist
dist=(${(Oa)o_dist})

# https://stackoverflow.com/questions/22434290/jq-bash-make-json-array-from-variable
outdated=$(npm outdated --json)
for dependency in $(echo "$outdated" | jq -r '. | keys | .[]'); do
    jq --arg dists "${(k)dist}" -s -r --arg dependency $dependency '
        ($dists | split(" ")) as $dists |
        .[0] as $o2 |
        [.[1]["dist-tags"] | to_entries[] | select(.key as $key | $dists | contains([$key]))] as $o1 |
        $o2 | to_entries[] | select(.key == $dependency) | .value.current as $current | {
            name: .key,
            current: .value.current,
            tags: [$o1[] | "\(.key) => \(.value)"] | join(", "),
            tag: [($o1[] | select(.value == $current) | .key), "OUTDATED"] | first
        } | select(.tag == "OUTDATED") | "\(.name) \(.current) \(.tags)"
    ' <(echo "$outdated") <(npm info $dependency --json)
done
