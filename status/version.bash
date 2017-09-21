package=$1
version=$2
current=$(jq -r --arg package "$package" --arg version "$version" '
    [
        (
            [ (.dependencies | to_entries[]), (.devDependencies | to_entries[]) ][] |
            select(.key == $package) |
            .value
        ),
        $version
    ] | first
' < package.json)
[[ "$version" = "$current" ]]
