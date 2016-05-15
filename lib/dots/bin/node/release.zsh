#!/usr/bin/env zsh

set -e

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

zparseopts -D -- -help=usage h=usage \
                 -title:=title i:=title \
                 -prefix:=prefix p:=prefix

version=$(dots node package version)
if [ "$1" = "major" ]; then
    major=${version%%.*}
    bump=$(( $major + 1 )).0.0
elif [ "$1" = "minor" ]; then
    major=${version%%.*}
    minor=${version#*.}
    minor=${minor%.*}
    echo $minor
    bump=$major.$(( $minor + 1 )).0
else
    majmin=${version%.*}
    micro=${version##*.}
    bump=$majmin.$(( $micro + 1 ))
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
