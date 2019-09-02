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
o_user=()
o_package=()

zparseopts -K -D \
    -canary=o_canary c=o_canary \
    -expire=o_expire e:=o_expire \
    -skip+:=o_skip s+:=o_skip \
    -package+:=o_package p+:=o_package \
    -user+:=o_user u+:=o_user

# https://unix.stackexchange.com/a/29748
function distributions () {
    local ref=$1; shift; local o=("$@")
    typeset -A k
    k=(${(@Oa)o})
    typeset -A aa
    for value in ${(k)k}; do
        if [[ $value = *=* ]]; then
            pair=("${(@s/=/)value}")
            aa[$pair[1]]=$pair[2]
        else
            aa[$value]=%
        fi
    done
    : ${(PA)ref::=${(kv)aa}}
}

typeset -A user package
distributions user ${(@)o_user}
distributions package ${(@)o_package}

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
    json=node_modules/$dependency/package.json
    if [[ ! -e "$json" ]]; then
        print -u2 "error: $json not installed" && exit 1
    fi
    version=$(jq -r '.version' <  "$json")
    info="$cache"/"$dependency"/json.json
    mkdir -p "${info%/*}"
    if [[ ! -e "$info" ]]; then
        mv =(npm view "$dependency" --json) "$info"
    fi
    typeset -A releases
    releases=($(jq -r '[ .["dist-tags"] | to_entries[] | .key, .value ] | join(" ")' < "$info"))
    u=$(jq -r '._npmUser | split(" ")[0]' < "$info")
    if [[ $package[$u] = '%' || $user[$u] = '%' ]]; then
        dists=("${(@k)releases}")
    elif [[ -n $package[$dependency] ]]; then
        dists=("${(@s/,/)package[$dependency]}")
    elif [[ -n $user[$u] ]]; then
        dists=("${(@s/,/)user[$u]}")
    else
        dists=(latest)
    fi
    candidates=()
    for dist in ${dists[@]}; do
        [[ -n ${releases[$dist]} ]] && candidates+=(${releases[$dist]})
    done
    # synonym for ${candidates[@]}
    s_releases=($(semver ${(@)candidates} | tail -r))
    release=${s_releases[1]}
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
