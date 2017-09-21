#!/bin/bash

cp ~/git/ecma/prolific/prolific.logger/.gitignore .

name=$(jq -r '.name' < package.json)

title= separator=''
for part in $(echo $name | tr '.' $'\n'); do
    title="$title""$separator""$(tr '[:lower:]' '[:upper:]' <<< ${part:0:1})${part:1}"
    separator=' '
done

echo "$title"

git add .
git commit -m 'Add local `.gitignore` to '"$title"'.'
