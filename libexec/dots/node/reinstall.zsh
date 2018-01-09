#!/usr/bin/env zsh

links=()
if [[ -d node_modules ]]; then
    while read -r line; do
        print will relink ${line#node_modules/}
        links+=($line)
    done < <(find node_modules -name .bin -prune -o -type l -print)
fi

rm -rf node_modules
npm install
if git ls-files node_modules --error-unmatch 2>/dev/null; then
    echo git checkout node_modules
    git checkout node_modules
fi

for link in ${links[@]}; do
    npm link ${link#node_modules/}
done
