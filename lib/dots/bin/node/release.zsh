#!/usr/bin/env zsh

set -e

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

zparseopts -a opts -D -- -help h -title: t: -prefix: p: -version: v: d -dry-run I -issueless

index=1
while [ $index -le $#opts ]; do
    case "${opts[$index]}" in
        -h|--help)
            echo help
            ;;
        -I|--issueless)
            issueless=1
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

[ -z "$1" ] && 1=micro
is_latest=""
tag=canary
version=$(dots node package version)
if [ -z "$bump" ]; then
    case "$1" in
        major)
            major=${version%%.*}
            bump="$(( $major + 1 )).0.0"
            ;;
        minor)
            major=${version%%.*}
            minor=${version#*.}
            minor=${minor%%.*}
            bump=$major.$(( $minor + 1 )).0
            ;;
        micro)
            major_minor_pre=${version%.*}
            micro=${version##*.}
            bump=$major_minor_pre.$(( $micro + 1 ))
            ;;
        alpha)
            major_minor=${version%.*.*}
            bump=$major_minor.0-alpha.0
            ;;
        beta)
            major_minor=${version%.*.*}
            bump=$major_minor.0-beta.0
            ;;
        rc)
            major_minor=${version%.*.*}
            bump=$major_minor.0-rc.0
            ;;
        final)
            major_minor=${version%.*.*}
            bump=$major_minor.0
            ;;
    esac
    case "$2" in
        alpha|beta|rc)
            bump="${bump}-${2}.0"
            ;;
    esac
    if [[ "$bump" != *-* ]]; then
        major=${bump%%.*}
        if [ "$major" -eq 0 ] || [ "$(( $major % 2 ))" -eq 1 ]; then
            tag=latest
        fi
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
        part=${part#@*/}
        title="$title$separator${(C)part[1,1]}$part[2,-1]"
        separator=' '
    done
fi

if ! git diff-index --quiet HEAD --; then
    echo "Work tree must be clean." 1>&2
    exit 1
fi
echo "$title $prefix$version -> $prefix$bump ($tag)"
[ "$dry_run" -eq 1 ] && exit
sed 's/\("version":.*"\)'$version'/\1'$bump'/' package.json > package.json.tmp
mv package.json.tmp package.json
git add .
git commit --dry-run
if [ "$issueless" -eq 1 ]; then
    git commit -m "Release $title $bump."
else
    issue=$(dots git issue create -m able -l enhancement "Release $title version $bump.")
    git commit -m "Release $title $bump."$'\n\nCloses #'$issue'.'
fi
git push origin HEAD
git tag "$prefix$bump"
git push origin --tags
npm publish --tag "$tag"
