#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots git release <options>

  options:

    -h,--help                   display this message
    -i,--issue   <string>       issue to use for commit message

usage

zparseopts -D -- -help=usage h=usage \
                 -issue:=issue i:=issue

[ -z "$usage" ] || usage

create_release() {
cat << BODY
### Issue by Issue

 * $1 #$2.
BODY
}

if [ "$issue[2]" ]; then
  body="$issue[2]"
else
  subject="$(git log -n 1 --pretty=format:'%s')" 
  body="$(git log -n 1 --pretty=format:'%b' | grep Closes)" 

  if [ -z $body ]; then
    exit 1
  fi
  body=$(echo $body | sed -e 's/^.*#\([0-9][0-9]*\).*$/\1/')
fi

subject=$(dots git issue get $body)

IFS=
issue=
found=0
written=0
if [ -e release.ft ]; then
  while read line; do
    if [[ "$line" =~ "#* Issue by Issue" ]]; then
      echo "$line"
      echo ""
      found=1
      line=
    fi
    if [ "$found" = 0 ]; then
      echo "$line"
    else
      issue="$issue$line"
      end=$(echo $issue | grep '.*#[0-9]\+\.$')
      if ! [ -z "$end" ]; then
        number=$(echo $end | sed -e 's/^.*#*\([0-9][0-9]*\).*$/\1/')
        if [ $number -lt $body -a $written = 0 ]; then
          echo " * $subject #$body."
          written=1
        fi
        echo "$issue"
        issue=
      fi
    fi
  done < release.ft
  if [ $written -eq 0 ]; then
    echo " * $subject #$body."
  fi
else
  create_release "$subject" "$body"
fi
