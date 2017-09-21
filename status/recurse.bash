#!/bin/bash

set -e

VISITED=()
skip=()

while [[ $# -gt 1 ]]; do
    case "$1" in
        -s|--skip)
            skip+=($2)
            shift
            ;;
        *)
            break
            ;;
    esac
    shift
done

function abend () {
    local message=$1
    echo "$message" 1>&2
    exit 1
}

function status_get_packages () {
    local property=$1
    cat package.json | jq -r '.'$property' | keys | .[]'
}

report=()

function status_inspect_project () {
    local caller=$1 name=$(jq -r '.name' < "package.json")
    shift
    if [[ " ${VISITED[@]} " =~ " ${name} " ]]; then
        return
    fi
    echo "--- $name ---"
    VISITED+=($name)
    if [[ " ${skip[@]} " =~ " ${name} " ]]; then
        echo "skip $name"
    elif ! "$@"; then
        echo "$caller"
        abend 'Test failed in `'$name'`.'
    fi
    status_inspect_dependencies "$@"
}

function status_inspect_dependencies () {
    local path=$(realpath ../..) root=
    if [[ $(basename $path) = "ecma" ]]; then
        root=./
    else
        root=../
    fi
    for package in $(status_get_packages dependencies; status_get_packages devDependencies); do
        [[ -e node_modules/$package/package.json ]] || abend '`'$package'` not installed in `'`pwd`'`.'
        local user=$(jq -r '.author.email' <  node_modules/$package/package.json) 
        if [[ "$user" != "alan@prettyrobots.com" ]]; then
            continue
        fi
        if [[ "$package" = *.* ]]; then
            parent=${package%.*}
            if [[ ! -z "$(ls -d ${root}../../*/$parent/$package 2> /dev/null)" ]]; then
                dir=$(ls -d ${root}../../*/$parent/$package)
            elif [[ ! -z "$(ls -d ${root}../../$parent/$package 2> /dev/null)" ]]; then
                dir=$(ls -d ${root}../../$parent/$package)
            else
                pwd
                abend 'cannot find directory for `'$package'`.'
            fi
        else
            dir=$(ls -d ${root}../../*/$package)
        fi
        [[ -e "$dir/package.json" ]] || abend "cannot find package in $dir"
        [[ $(jq -r '.name' < "$dir/package.json") = "$package" ]] || abend "$package not in $dir/package"
        pwd=$(pwd)
        pushd "$dir" > /dev/null
        status_inspect_project "$pwd" "$@"
        popd > /dev/null
    done
}

status_inspect_project "$(pwd)" "$@"
