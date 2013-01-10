function airbrush () {
  local histsize=$HISTSIZE
  if [ ! -z "$1" ]; then
    fc -AI
    history | grep -e "$1"
    HISTSIZE=0
    sed -i -e '/'"$1"'/d' "$HISTFILE"
    HISTSIZE=$histsize
    fc -RI
  fi
}

# Launch screen with a name name and a fresh bash login.
function scn () {
    screen -t $1 zsh -l
}
