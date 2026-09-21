#!/bin/sh

[ "$#" -eq 1 ] || exit 0

slug=$1
relative=projects/$slug/agenda.md

for vault in athenaeum assistance; do
    if [ -f "$HOME/code/$vault/$relative" ]; then
        if /opt/homebrew/bin/obsidian vault="$vault" open path="$relative" >/dev/null 2>&1; then
            /usr/bin/open -a Obsidian
            exit 0
        fi

        encoded=$(/opt/homebrew/bin/jq -rn --arg path "$relative" '$path | @uri') || exit 0
        /usr/bin/open "obsidian://open?vault=$vault&file=$encoded"
        exit 0
    fi
done

exit 0
