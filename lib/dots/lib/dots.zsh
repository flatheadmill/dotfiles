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
  local option=$1
  shift;
  which "_dots_$option" > /dev/null && {
    "_dots_$option" $*
  } || dots $option "$*"
}
