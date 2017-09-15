USAGE=$(sed 's/^  //g' </dev/stdin)

usage() {
    local code=$1
    echo "$USAGE" 2>&1
    echo "" 2>&1
    if [ -z "$code" ]; then
        code=0
    fi
    exit $code
}

abend() {
    local message=$1
    echo "error: $message" 2>&1
    exit 1
}

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
