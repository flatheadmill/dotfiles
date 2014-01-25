usage=$(</dev/stdin)

hello() {
  echo "hello, world"!
}

perpetuate() {
  local executable="${1%.*}/$2"
  shift; shift
  "$executable".* "$*"
}
