#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

version=$(dots node version)
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

echo "$version -> $bump"
sed 's/\("version":.*"\)'$version'/\1'$bump'/' package.json > package.json.tmp
mv package.json.tmp package.json
git add .
git commit --dry-run
issue=$(dots git issue create -m able -l enhancement "Release version $bump.")
git commit -m "Release $bump."$'\n\nCloses #'$issue'.'
git push origin HEAD
git tag "v$bump"
git push origin --tags
npm publish
