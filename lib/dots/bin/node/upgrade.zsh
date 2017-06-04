#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
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

package=$1


if [ -z "$title" ]; then
    title='' separator=''
    parts=(${(s:.:)package})
    for part in $parts; do
        part=${part#@*/}
        title="$title$separator${(C)part[1,1]}$part[2,-1]"
        separator=' '
    done
fi

current=$(jq -r --arg key $package \
    '.dependencies | to_entries[] | select(.key == $key) | .value' < package.json)

if [ -z "$version" ]; then
    version=$(dots node latest < <(npm info $package --json))
    if [[ "$current" = *.x ]]; then
        version=${version%.*}.x
    fi
fi

echo "$title $current -> $version"
[ "$dry_run" -eq 1 ] && exit

sed 's/\("'"$package"'":[[:space:]]*\)".*"/\1"'$version'"/' package.json  > package.tmp.json
mv package.tmp.json package.json

git commit -a -m 'Upgrade `'$package'` to '$version'.'
