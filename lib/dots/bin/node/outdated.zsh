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
o_sort=()

zparseopts -K -D -a o_dist d+: -dist+: e:=o_expire p+:=o_package g=o_greatest

if [[ ${#o_dist} -eq 0 ]]; then
    o_dist=(-d latest)
fi

typeset -A dists
dists=(${(Oa)o_dist})

function status_get_packages () {
    local file=$1 collection=$2
    # TODO Make $property an argument to `jq`.
    jq --arg collection "$collection" -r '
        [ . | to_entries[] | select(.key == $collection) | .value | to_entries[] | .key, .value ] | join(" ")
    ' < "$file"
}

typeset -A packages
packages=($(status_get_packages package.json dependencies) $(status_get_packages package.json devDependencies))

typeset -A i_packages
if [[ ${#o_package} -eq 0 ]]; then
    i_packages=(${(kv)packages})
else
    i_packages=(${(Oa)o_package})
fi

CACHE=~/.usr/var/cache/dots/node/outdated/dist-tags

mkdir -p "$CACHE"

find "$CACHE" -type f -mmin +"$o_expire[2]" -exec rm {} \;

SORT=$(which gsort || which sort)

for dependency in ${(k)packages}; do
    if ! (( $+i_packages[$dependency] )); then
        continue
    fi
    package=node_modules/$dependency/package.json
    if [[ ! -e "$package" ]]; then
        print -u2 "$package not installed"
        exit 1
    fi
    version=$(jq -r '.version' <  "$package")
    info="$CACHE"/"$dependency"/dist-tags.json 
    mkdir -p "${info%/*}"
    if [[ ! -e "$info" ]]; then
        mv =(npm view "$dependency" dist-tags --json) "$info"
    fi
    typeset -A tags
    tags=($(jq -r '[ . | to_entries[] | .key, .value ] | join(" ")' < "$info"))
    if [[ -n "${o_greatest[1]}" ]]; then
        tags=($({ $SORT -k 2Vr | head -n 1; } < <(for k v in  ${(kv)tags}; do echo $k $v; done)))
    fi
    found=0
    for dist in ${(k)dists}; do
        if [[ $version = $tags[$dist] ]]; then
            found=1
        fi
    done
    if [[ $found -eq 0 ]]; then
        pairs=()
        for tag release in ${(kv)tags}; do
            pairs+=("$tag => $release")
        done
        print $dependency@$version $packages[$dependency] ${(j: :)pairs}
    fi
done
