usage=$(</dev/stdin)

hello() {
  echo "hello, world"!
}

_dots_perpetuate() {
  local executable="${1%.*}/$2"
  shift; shift
  "$executable".* $*
}

_dots_foo() {
  echo "$*"
}

dots() {
  if [ "$1" = "util" ]; then
    shift; local option=$1; shift
    which "_dots_$option" > /dev/null && {
      "_dots_$option" $*
    }
  else
    $DOTS_MOUNT/bin/dots $*
  fi
}
