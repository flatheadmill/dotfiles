#!/bin/bash

script=$(realpath $0)
dir=$(dirname $script)

trap printout TERM

function printout () {
    for message in "${report[@]}"; do
        echo "$message"
    done
}

function abend () {
    local message=$1
    echo "$message" 1>&2
    exit 1
}

function status_get_packages () {
    local property=$1
    cat package.json | jq -r '.'$property' | keys | .[]'
}

function status_get_bigeasy_packages () {
    for package in $(status_get_packages dependencies); do
        if [[ $(jq -r '._npmUser.name' <  node_modules/$package/package.json) = "bigeasy" ]]; then
            echo $package
        fi
    done
    for package in $(status_get_packages devDependencies); do
        if [[ $(jq -r '._npmUser.name' <  node_modules/$package/package.json) = "bigeasy" ]]; then
            echo $package
        fi
    done
}

function yaml2json() {
    ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' $*
}

report=()
skip=("$@")
VISITED=()

function status_project_tests () {
    local name=$(jq -r '.name' < "package.json")
    if [[ " ${VISITED[@]} " =~ " ${name} " ]]; then
        return
    fi
    VISITED+=($name)
    ( \
        ! [ -z "$(git ls-files --other --exclude-standard --directory)" ] || \
        ! git diff --exit-code > /dev/null || \
        ! git diff --exit-code --cached > /dev/null \
        ) && abend 'Working directory is dirty in `'$name'`.'
    if ! grep "$(date +%Y)" LICENSE | grep Copyright > /dev/null; then
        abend 'LICENSE out of date in package `'$name'`.'
    fi
    local build_versions=($(jq -r '[.node_js[]] | @tsv' <(yaml2json .travis.yml)))
    if [[ "${build_versions[@]}" != "0.10 0.12 4 6 7" ]]; then
        abend 'Travis CI build versions incomplete `'$name'`.'
    fi
    if [[ "$(<package.json)" != "$(dots node format package.json)" ]]; then
        abend '`package.json` is untidy in `'$name'`.'
    fi
    echo "--- $name ~ tests ---"
    npm test
    echo "--- $name ~ coverage ---"
    if [[ ! -e node_modules/.bin/istanbul ]]; then
        npm install istanbul
    fi
    local count=0
    for file in $(find . ! -path '*/node_modules/*' -name \*.t.js); do
      node_modules/.bin/istanbul cover -x 't/**' -x '*/t/**' $file > /dev/null 2>&1
      mv coverage/coverage.json coverage/coverage$count.json
      count=$(expr $count + 1)
    done
    node_modules/.bin/istanbul report --format text 
    echo "--- $name ~ outdated ---"
    local outdated=$(npm outdated --json)
    for dependency in $(echo "$outdated" | jq -r '. | keys | .[]'); do
        echo $dependency
        jq -s -r '
            .[0] as $o2 |
            .[1]["dist-tags"] | to_entries as $o1 |
            $o2 | to_entries[] | .value.current as $current | {
                name: .key,
                current: .value.current,
                tag: [($o1[] | select(.value == $current) | .key), "OUTDATED"] | first
            } | "\(.name) \(.current) \(.tag)"
        ' <(echo "$outdated") <(npm info $dependency --json)
    done
    echo "--- $name ~ docs ---"
    [[ -d node_modules/wiseguy ]] || npm link wiseguy
    wg make
    if ( \
        ! [ -z "$(git -C docs ls-files --other --exclude-standard --directory)" ] || \
        ! git -C docs diff --exit-code > /dev/null || \
        ! git -C docs diff --exit-code --cached > /dev/null \
        )
    then
        report+=('`docs` are dirty in `'$name'`.')
        echo '`docs` are dirty in `'$name'`.'
    fi
}

function status_inspect_project () {
    local name=$(jq -r '.name' < "package.json")
    echo ${name}
    if [[ " ${VISITED[@]} " =~ " ${name} " ]]; then
        return
    fi
    if [[ ! " ${skip[@]} " =~ " ${name} " ]]; then
        status_project_tests
    fi
    VISITED+=($name)
    status_inspect_dependencies
}

function status_inspect_dependencies () {
    local name=$(jq -r '.name' < "package.json") root= package=
    if [[ "$name" = *.* ]]; then
        root=../
    else
        root=./
    fi
    for package in $(status_get_bigeasy_packages); do
        if [[ "$package" = *.* ]]; then
            parent=${package%.*}
            dir=$(ls -d ${root}../../*/$parent/$package)
        else
            ls -d ${root}../../*/$package
            ls -d `pwd`/${root}../../*/$package
            dir=$(ls -d ${root}../../*/$package)
        fi
        [[ -e "$dir/package.json" ]] || abend "cannot find package in $dir"
        [[ $(jq -r '.name' < "$dir/package.json") = "$package" ]] || abend "$package not in $dir/package"
        pushd "$dir" > /dev/null
        status_inspect_project
        popd > /dev/null
    done
}

status_inspect_project

printout
