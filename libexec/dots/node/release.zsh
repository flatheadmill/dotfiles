#!/usr/bin/env zsh

set -e

zmodload zsh/pcre
setopt REMATCH_PCRE

source $dots <<- usage
  usage: dots node install

  description:

    Bump version number and publish a release.
usage

if ! which jq > /dev/null 2>&1; then
    abend "jq is missing."
fi

if ! which node > /dev/null 2>&1; then
    abend "node is missing."
fi

if [[ ! -e ~/.dots ]]; then
    abend "~/.dots is missing."
fi

if [[ $(jq '.private' < package.json) = "true" ]]; then
    abend "Repository is private."  
fi

zparseopts -a opts -D -- n: -notes: -help h -final f -identifier: i: -title: t: -prefix: p: -bump: b: -version: v: d -dry-run I -issueless

index=1
while [ $index -le $#opts ]; do
    case "${opts[$index]}" in
        -h|--help)
            echo help
            ;;
        -b|--bump)
            let index+=1
            bump=$opts[$index]
            ;;
        -n|--notes)
            let index+=1
            o_notes=$opts[$index]
            ;;
        -f|--final)
            final=1
            ;;
        -I|--issueless)
            issueless=1
            ;;
        -i|--identify)
            let index+=1
            identify=$opts[index]
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
            version=$opts[$index]
            ;;
    esac
    let index+=1
done

if [[ -n $identify ]]; then
    identifiers=(alpha beta rc)
    [[ -z ${identifiers[(r)$identify]} ]] && \
        abend "$identify is not a valid identifier -> use alpha, beta or rc"
fi
[[ -n "$version" ]] && [[ -n "$bump" ]] && abend "either version or bump"
[[ -n "$identify" ]] && [[ -z "$bump" ]] && \
    abend "bump is required when setting identifier"
[[ -n "$identify" ]] && [[ "$bump" != major && "$bump" != minor ]] && \
    abend "$identify option only works with bump of major or minor"
git diff-index --quiet HEAD -- || abend "work tree must be clean"

current=$(dots node package version)

[[ "$current" =~ '^(\d+)\.(\d+)\.(\d+)(?:$|-(alpha|beta|rc)\.(\d+)$)' ]] || \
    abend "bad version number $version"

local major=$match[1] minor=$match[2] micro=$match[3] identifier=$match[4] pre=$match[5]

if [[ -n "$identify" ]]; then
    pre=0
    identifier=$identify
fi

local untag=
if [[ -z "$version" ]];  then
    if [[ $final -eq 1 ]]; then
        bump=none
    elif [[ -z "$bump" ]]; then
        if [[ -z "$identifier" ]]; then
            bump=micro
        else
            bump=pre
        fi
    fi
    case "$bump" in
        major)
            let major+=1
            minor=0
            micro=0
            ;;
        minor)
            let minor+=1
            micro=0
            ;;
        micro)
            let micro+=1
            ;;
        pre)
            let pre+=1
            ;;
        none)
            ;;
    esac
    version="$major.$minor.$micro"
fi

if [[ -n "$identifier" ]]; then
    version+="-$identifier.$pre"
    tag=canary
elif [[ "$version" = 0.* ]]; then
    tag=canary
else
    tag=latest
    untag=canary
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

echo "$title $prefix$current -> $prefix$version ($tag)"

[[ "$dry_run" -eq 1 ]] && exit

sed 's/\("version":.*"\)'$current'/\1'$version'/' package.json > package.json.tmp
mv package.json.tmp package.json
git add .
git commit --dry-run
if [[ -n $o_notes ]]; then
    issue=$(dots git issue create -m able -l enhancement "Release $title version $version.")
    git commit -m "Release $title $version."$'\n\n'$o_notes$'\n\nCloses #'$issue'.'
elif [ "$issueless" -eq 1 ]; then
    git commit -m "Release $title $version."
else
    issue=$(dots git issue create -m able -l enhancement "Release $title version $version.")
    git commit -m "Release $title $version."$'\n\nCloses #'$issue'.'
fi
git push origin HEAD
git tag "$prefix$version"
git push origin --tags
npm publish --tag "$tag"
if [[ -n $untag ]]; then
    npm info "$name" --json | jq -e --arg tag $untag -r '
        .["dist-tags"] | [to_entries[] | select(.key == $tag)] | length == 1
    ' > /dev/null && npm dist-tag rm "$name" "$untag" || echo "no existing $untag tag"
fi

echo rm -rf ~/.usr/var/cache/dots/node/outdated/dist-tags/$name
rm -rf ~/.usr/var/cache/dots/node/outdated/dist-tags/$name
