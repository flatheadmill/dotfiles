#!/usr/bin/env zsh

set -e

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

zparseopts -a opts -D -- -help h -title: t: -prefix: p: -version: v: d -dry-run

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
        -p|--prefix)
            let index+=1
            prefix=$opts[$index]
            ;;
        -v|--version)
            let index+=1
            bump=$opts[$index]
            ;;
    esac
    let index+=1
done

version=$(dots node package version)
if [ -z "$bump" ]; then
    if [ "$1" = "major" ]; then
        major=${version%%.*}
        bump=$(( $major + 1 )).0.0
    elif [ "$1" = "minor" ]; then
        major=${version%%.*}
        minor=${version#*.}
        minor=${minor%.*}
        bump=$major.$(( $minor + 1 )).0
    else
        majmin=${version%.*}
        micro=${version##*.}
        bump=$majmin.$(( $micro + 1 ))
    fi
fi

if [ -z "$prefix" ]; then
    name=$(dots node package name)
    prefix='v'
    if [[ "$name" = *.* ]]; then
        prefix=${name#*.}-v
    fi
fi

if [ -z "$title" ]; then
    title='' separator=''
    parts=(${(s:.:)name})
    for part in $parts; do
        title="$title$separator${(C)part[1,1]}$part[2,-1]"
        separator=' '
    done
fi

echo "$title $prefix$version -> $prefix$bump"
[ "$dry_run" -eq 1 ] && exit
sed 's/\("version":.*"\)'$version'/\1'$bump'/' package.json > package.json.tmp
mv package.json.tmp package.json
git add .
git commit --dry-run
issue=$(dots git issue create -m able -l enhancement "Release $title version $bump.")
git commit -m "Release $title $bump."$'\n\nCloses #'$issue'.'
git push origin HEAD
git tag "$prefix$bump"
git push origin --tags
npm publish
