function airbrush () {
  local histsize=$HISTSIZE
  if [ ! -z "$1" ]; then
    history | grep -e "$1"
    HISTSIZE=0
    LC_ALL=C sed -i -e '/'"$1"'/d' "$HISTFILE"
    HISTSIZE=$histsize
    fc -R
  fi
}

# http://brettterpstra.com/2013/02/09/quick-tip-jumping-to-the-finder-location-in-terminal/
function cdf () {
    target=`osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)'`
    if [ "$target" != "" ]; then
        cd "$target"
    else
        echo 'No Finder window found' >&2
    fi
}
