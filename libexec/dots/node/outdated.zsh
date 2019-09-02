#!/usr/bin/env zsh

# TODO Switches to allow development and canary.

source $dots <<- usage
  usage: dots node outdated

  desctiption:

    Determine which modules are outdated in the current project.
usage

set -e

o_expire=(-e 10)
o_package=()
o_skip=()
o_repository=()

zparseopts -K -D c=o_canary e:=o_expire -skip+:=o_skip s+:=o_skip

if [[ ${#o_dist} -eq 0 ]]; then
    o_dist=(-d latest)
fi

# `Oa` sorts an array in reverse index order. We reverse the order of `o_skip`
# so that it is argument value followed by argument name. We create an
# associative array with that result and the keys are the argument name making
# the associative array effectively a set.
typeset -A skip
skip=(${(Oa)o_skip})

function status_get_packages () {
    local file=$1 collection=$2
    # TODO Make $property an argument to `jq`.
    jq --arg collection "$collection" -r '
        [ . | to_entries[] | select(.key == $collection) | .value | to_entries[] | .key, .value ] | join(" ")
    ' < "$file"
}

typeset -A packages
packages=($(status_get_packages package.json dependencies) $(status_get_packages package.json devDependencies))


cache=~/.usr/var/cache/dots/node/outdated/dist-tags

mkdir -p "$cache"

find "$cache" -type f -mmin +"$o_expire[2]" -exec rm {} \;

SORT=$(which gsort || which sort)

for dependency in ${(k)packages}; do
    if (( $+skip[$dependency] )); then
        continue
    fi
    package=node_modules/$dependency/package.json
    if [[ ! -e "$package" ]]; then
        print -u2 "error: $package not installed" && exit 1
    fi
    version=$(jq -r '.version' <  "$package")
    info="$cache"/"$dependency"/package.json 
    mkdir -p "${info%/*}"
    if [[ ! -e "$info" ]]; then
        mv =(npm view "$dependency" --json) "$info"
    fi
    typeset -A releases
    releases=($(jq -r '[ .["dist-tags"] | to_entries[] | .key, .value ] | join(" ")' < "$info"))
    if [[ -z $o_canary ]]; then
        release=${releases[latest]}
    else
        s_releases=($(semver ${(v)releases} | tail -r))
        release=${s_releases[1]}
    fi
    if [[ $version != $release ]]; then
        typeset -A tags
        values=(${(v)releases})
        keys=(${(k)releases})
        tags=(${(@)values:^keys})
        pairs=()
        for t v in ${(kv)releases}; do
            pairs+=("$t => $v")
        done
        print "$dependency (${tags[$release]}) $version < $release"
    fi
done
