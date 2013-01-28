#!/bin/sh

dir=`dirname $0`
dir=`cd "$dir" && pwd`

. "$HOME/.secrets/workstation/s3"
. "$HOME/.secrets/workstation/backup"

export AWS_SECRET_ACCESS_KEY
export AWS_ACCESS_KEY_ID
export PASSPHRASE

export PATH=$HOME/.usr/bin:$PATH

ulimit -n 1024

hostname=`hostname | sed s/.local$//`

echo "`date` $1 $USER $HOME"  >> /Users/alan/monkey

abend () {
  echo "$1" 1>&2
  exit 1
}

echo "run at `date`" >> $HOME/monkey

chain_end_time () {
  local collection=$1 when
  when=`duplicity collection-status s3+http://archivals/$hostname/home/$collection  \
    | grep '^Chain end time: ' | sed 's/Chain end time: //'`
  [ -z "$when" ] && echo 0 || date -j -f "%a %b %d %T %Y" "$when" "+%s"
}  

if [ ! -e "$HOME/.backups" ]; then
  abend "error: create a list of directories to backup in $HOME/.backups"
fi

[ -e "$HOME/.backups/running" ] && exit 0

case "$1" in
  interval)
    end=`chain_end_time daily`
    now=`date "+%s"`
    since=`expr $now - $end`
    if [ "$since" -ge 86400 ]; then
      $0 backup
    fi
    ;;
  backup)
    if [ "$2" = "full" ]; then
      full="full"
    fi
    touch "$HOME/.backups/running"
    (duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
          --include-globbing-filelist "$HOME/.backups/daily" \
          --exclude "**" \
          "$HOME" "s3+http://archivals/$hostname/home/daily" 2>&1) \
      | tee -a "$HOME/.backups/backup.log" | mail -s "$hostname backup `date`" $USER
    rm "$HOME/.backups/running"
    ;;
  dry-run)
    duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
          --include-globbing-filelist "$HOME/.backups/daily" \
          --exclude "**" \
          --dry-run \
          "$HOME" "s3+http://archivals/$hostname/home/daily" 2>&1
    ;;
  status)
    duplicity collection-status "s3+http://archivals/$hostname/home/daily"
    ;;
  hello)
    echo mail -s "Hello, $USER"'!' $USER >> $HOME/monkey
    echo $USER | mail -s "Hello, $USER"'!' $USER
    sleep 3;
    ;;
  *)
    echo $USER | mail -s unsupported $USER
    echo unsupported ; exit 1
    ;;
esac

exit 0

last=`duplicity collection-status s3+http://archivals/$hostname/home/git \
  | grep '^Chain end time: ' | sed 's/Chain end time: //'`

now=`date "+%s"`
since=`expr $now - $last`

echo $since
if [ "$since" -ge 600 ]; then
  for dir in git; do
    (duplicity -v8 --include "$HOME/$dir" --exclude "**" "$HOME" "s3+http://archivals/$hostname/home/$dir" 2>&1) | \
      mail -s "$hostname backup" $USER
  done
fi
