#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

version=$(dots node version)
majmin=${version%.*}
micro=${version##*.}
bump=$majmin.$(( $micro + 1 ))

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
