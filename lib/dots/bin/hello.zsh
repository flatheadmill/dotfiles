source $dots <<- usage
  usage: dots hello
usage

echo $0
shift
echo "$@"
