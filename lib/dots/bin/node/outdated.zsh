#!/usr/bin/env zsh

# TODO Switches to allow development and canary.

source $dots <<- usage
  usage: dots node outdated

  desctiption:

    Determine which modules are outdated in the current project.
usage

set -e

outdated=$(npm outdated --json)
for dependency in $(echo "$outdated" | jq -r '. | keys | .[]'); do
    jq -s -r --arg dependency $dependency '
        .[0] as $o2 |
        .[1]["dist-tags"] | to_entries as $o1 |
        $o2 | to_entries[] | select(.key == $dependency) | .value.current as $current | {
            name: .key,
            current: .value.current,
            tags: [$o1[] | "\(.key) => \(.value)"] | join(", "),
            tag: [($o1[] | select(.value == $current) | .key), "OUTDATED"] | first
        } | select(.tag == "OUTDATED") | "\(.name) \(.current) \(.tag) \(.tags)"
    ' <(echo "$outdated") <(npm info $dependency --json)
done
