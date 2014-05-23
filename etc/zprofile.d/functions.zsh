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
