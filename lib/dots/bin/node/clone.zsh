#!/bin/zsh

NPM=npm

function abend () {
    local message=$1
    echo "$message" 1>&2
    exit 1
}

function get_packages () {
    #local package=$1 property=$2
    #$NPM -s info "$package" "$property" --json | jq -r 'if .type == "inspect" then .data else . end | keys | .[]'
    local property=$1
    # TODO Make $property an argument to `jq`.
    cat package.json | jq -r '.'$property' | keys | .[]'
}

function inspect_dependencies () {
    local dir=$(realpath ../..) root=
}

dir=$(realpath ../..) root=
if [[ $(basename $dir) = "ecma" ]]; then
    root=./
else
    root=../
fi

for package in $(get_packages dependencies; get_packages devDependencies); do
    install=1
    if [[ $package = *.* ]]; then
        echo nope
    else
        ecma=$(realpath ../..)
        if [[ -n $(echo ${root}/../../*/$package(NY1)) ]]; then
            install=0
        fi
    fi
    [[ install -eq 0 ]] && continue
    repository=$($NPM -s info "$package" repository.url --json | jq -r '.')
    if [[ $repository =~ ^git\\+https:\/\/github\.com\/bigeasy\/ ]]; then
        echo woot
        repo=git@github.com:bigeasy/${repository##*/bigeasy/}
        dir=$(mktemp -d)
        git clone --recursive "$repo" "$dir"
        category=$(jq -r '.keywords[0]' < "$dir"/package.json)
        mv "$dir" "$ecma/$category/$package"
        (cd "$ecma/$category/$package" && npm link wiseguy && node_modules/.bin/wg make)
    fi
done
