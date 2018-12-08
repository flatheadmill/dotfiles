#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node recurse <options> [command]

  options:

    -s, --skip
      Do not run the command for the given module. This option may be repeated
      multiple times to specify multiple modules.

    -r, --root

  desctiption:

    Apply the given comnand to all project dependencies.
usage

set -e

visited=()
executed=()
o_skip=()
o_root=()

# I've always supported long form arguments but now I'm deciding not to for my
# own little utilities for a while. See if I really miss them.
#
# Notes on `zparseopts`.
#
# http://grml.org/zsh/zsh-lovers.html#_shell_scripting
# https://linux.die.net/man/1/zshmodules (docs)
zparseopts -D -a o_skip s+: -skip+: r=o_root -root=o_root

# `zparseopts` will add the argument to the array along with the value creating
# an array with argument followed by value. We don't need the argument if we are
# placing our values in a specific array. We are gathering up multiple values
# for our skip argument so we end up with an array where values alternate
# between the useless argument switches (i.e. `-s`) and the useful argument
# value. We want just an array of values.
#
# Here the author users an loop to visit the values.
#
# https://coderwall.com/p/pav1uw/zsh-option-parsing-with-zparseopts

# Instead of a loop we create an associative array from a reversed copy of the
# array created by `zparseopts`. Reversing the array means that the keys are
# going to be the argument values and the values are going to be the argument
# switches. Now we can use the associative array to test for skipping. Note that
# you could aslo create an array of values using the `(k)` expansion.
typeset -A skip
skip=(${(Oa)o_skip})

function abend () {
    local message=$1
    echo "$message" 1>&2
    exit 1
}

# TODO why `status_`?

function status_get_packages () {
    local property=$1
    # TODO Make $property an argument to `jq`.
    cat package.json | jq -r '.'$property' | keys | .[]'
}

report=()

function status_inspect_project () {
    local caller=$1 name=$(basename $(pwd)) key=
    # local caller=$1 name=$(jq -r '.name' < "package.json") key=
    shift
    if [[ "$o_root" != "" && "$name" = *.* ]]; then
        key=${name%%.*} 
    else
        key=$name
    fi
    # https://stackoverflow.com/questions/5203665/zsh-check-if-string-is-in-array
    if (( ${visited[(I)$name]} )); then
        return
    fi
    visited+=($name)
    if ! (( ${executed[(I)$key]} )); then
        if [[ "$key" != "$name" ]]; then
            pushd ".." > /dev/null
            echo "--- $name -> $key ---"
        else
            echo "--- $name ---"
        fi
        executed+=($key)
        if (( $+skip[$name] )); then
            echo "skip $name"
        elif ! { "$@"; }; then
            echo "$caller"
            abend 'Test failed in `'$name'`.'
        fi
        if [[ "$key" != "$name" ]]; then
            popd > /dev/null
        fi
    fi
    status_inspect_dependencies "$@"
}

function status_inspect_dependencies () {
    local dir=$(realpath ../..) root=
    if [[ $(basename $dir) = "ecma" ]]; then
        root=./
    else
        root=../
    fi
    for package in $(status_get_packages dependencies; status_get_packages devDependencies); do
        [[ -e node_modules/$package/package.json ]] || abend '`'$package'` not installed in `'`pwd`'`.'
        email=$(
            jq '
                if .author == null then
                    false
                else
                    if .author | type == "object" then
                        .author.email == "alan@prettyrobots.com"
                    else
                        .author | test(".*<alan@prettyrobots.com>$")
                    end
                end
            ' < node_modules/$package/package.json
        )
        if [[ "$email" != 'true' ]]; then
            continue
        fi
        if [[ "$package" = *.* ]] || [[ "$package" = *.*.* ]]; then
            parent=${package%%.*}
            # http://www.refining-linux.org/archives/37/ZSH-Gem-2-Extended-globbing-and-expansion/
            #
            # Sought a way to use expansion in a conditional. Could as easily
            # have read the expansion into an array, then tested the array, then
            # used the array value if it passed the test. The EXTENDED_GLOB
            # solution looks interesting but as noted in the accepted response,
            # I don't want to set switches if I don't have to.
            #
            # https://stackoverflow.com/questions/41502846/zsh-test-whether-a-file-matching-a-pattern-exists
            if [[ -n $(echo ${root}../../*/$parent/$package(NY1)) ]]; then
                dir=$(ls -d ${root}../../*/$parent/$package)
            elif [[ -n $(echo ${root}../../$parent/$package(NY1)) ]]; then
                dir=$(ls -d ${root}../../$parent/$package)
            else
                pwd
                abend 'cannot find directory for `'$package'`.'
            fi
        else
            # dir=$(ls -d ${root}../../*/$package)
            if [[ -n $(echo ${root}../../*/$package(NY1)) ]]; then
                dir=$(ls -d ${root}../../*/$package)
            elif [[ -n $(echo ${root}../../$package(NY1)) ]]; then
                dir=$(ls -d ${root}../../$package)
            else
                pwd
                abend 'cannot find directory for `'$package'`.'
            fi
            package_name=$(jq -r '.name' < "$dir/package.json")
            if [[ "$package_name" != "$package" ]]; then
                dir=$(ls -d $dir/$package_name)
            fi
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
