#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node link [projects]

  description:

    Link projects to one another.
usage

zparseopts -a opts -D -- -help h -title: t: -version: v: d -dry-run

index=1
while [ $index -le $#opts ]; do
    case "${opts[$index]}" in
        -h|--help)
            echo help
            ;;
        -d|--dry-run)
            dry_run=1
            ;;
        -t|--title)
            let index+=1
            title=$opts[$index]
            ;;
        -v|--version)
            let index+=1
            bump=$opts[$index]
            ;;
    esac
    let index+=1
done

packages=()
while [[ $# -ne 0 ]]; do
    file=$1
    name=$(jq -r '.name' $file)
    packages+=("$name:$file")
    shift
done

function get_required() {
    for string in $(grep 'require\([^)]*\)' "$@" | sed 's/.*require(\([^)]*\)).*/\1/'); do
        node -p "$string" 2>/dev/null;
    done | sort | uniq
}

typeset -A required
for pair in "${packages[@]}"; do
    pair=("${(@s/:/)pair}")
    key="${pair[0]}"
    deps="${required[${pair[0]}]}"
    if [[ -z "$deps" ]]; then
        deps=$(get_required "${pair[1]}"/*.js) 
        required[key]=deps
        echo "deps ${required[$key]}"
    fi
done
