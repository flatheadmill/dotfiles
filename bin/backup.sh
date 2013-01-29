#!/bin/sh

suffix="-tmp-$$-`date +%H-%M-%S`"

trap "tidy" SIGHUP SIGINT SIGTERM

tidy () {
  rm -rf /tmp/*$suffix*
  exit $1
}

. "$HOME/.secrets/workstation/s3"
. "$HOME/.secrets/workstation/backup"

export AWS_SECRET_ACCESS_KEY
export AWS_ACCESS_KEY_ID
export PASSPHRASE

export PATH=$HOME/.usr/bin:$PATH

ulimit -n 1024

hostname=`hostname | sed 's/\([^.]*\).*$/\1/'`

abend () {
  echo "$1" 1>&2
  tidy 1
}

chain_end_time () {
  local collection=$1 when
  when=`duplicity collection-status s3+http://archivals/$hostname/home/$collection  \
    | grep '^Chain end time: ' | sed 's/Chain end time: //'`
  [ -z "$when" ] && echo 0 || date -j -f "%a %b %d %T %Y" "$when" "+%s"
}  

duplicity_base () {
  $HOME/.dotfiles/bin/backup.sh url
}

duplicity_exec () {
  $HOME/.dotfiles/bin/backup.sh duplicity "$@"
}

duplicity_listing () {
  duplicity_exec list-current-files `duplicity_base`/$directory | \
    tail -n +3 | \
    sed 's/[A-Za-z]\{3\} [A-Za-z]\{3\} \{1,2\}[0-9]\{1,2\} \([0-9]\{2\}:\)\{2\}[0-9]\{2\} [0-9]\{4\} //'
}

strip_listing () {
  sed -e '/.DS_Store$/d' -e '/.AppleDouble/d' -e '/^$/d'
}

directory_has_addtions () {
  directory=$1

  duplicity_listing $directory > /tmp/listing$suffix.txt

  # Assert that we correctly stripped the date out of the Duplicity listing.
  # Note the use of the UNIX path separator as a regex operator for sed.
  start=`echo "$directory" | grep -o / | wc -l`
  start=`expr 2 + $start`
  lines=`tail -n +$start /tmp/listing$suffix.txt | sed '\:^'$directory':d' | wc -l`
  [ $lines -eq 0 ] || abend "could not strip dates from Duplicity listing: $lines"

  length=`expr ${#directory} + 2`
  cut -c $length- /tmp/listing$suffix.txt | strip_listing | sort > /tmp/stored

  (cd "$HOME/$directory" && find .) | cut -c 3- | strip_listing | sort > /tmp/actual

  ! diff /tmp/stored /tmp/actual > /dev/null
}

if [ ! -e "$HOME/.backups" ]; then
  abend "error: create a list of directories to backup in $HOME/.backups"
fi

[ -e "$HOME/.backups/running" ] && exit 0

case "$1" in
  since)
    end=`chain_end_time daily`
    now=`date "+%s"`
    expr $now - $end
    ;;
  interval)
    since=`$0 since`
    if [ "$since" -ge 86400 ]; then
      $0 daily
    fi
    while read directory; do
      if directory_has_addtions "$directory"; then
        $0 posterity "$directory"
      fi
    done < "$HOME/.backups/posterity"
    ;;
  additions)
    directory_has_addtions $2 && tidy 0 || tidy 1
    ;;
  posterity)
    if [ "$2" = "full" ]; then
      full="full"
      directory="$3"
    else
      directory="$2"
    fi
    touch "$HOME/.backups/running"
    (duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
          --include "$HOME/$directory" \
          --exclude "**" \
          "$HOME" "s3+http://archivals/$hostname/home/$directory" 2>&1) \
      | tee -a "$HOME/.backups/backup.log" | tee | mail -s "$hostname backup of $directory for posterity on `date`" $USER
    rm "$HOME/.backups/running"
    ;;
  changes)
    directory="$2"
    duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
          --include "$HOME/$directory" \
          --exclude "**" \
          --dry-run \
          "$HOME" "s3+http://archivals/$hostname/home/$directory" 2>/dev/null
    ;;
  daily)
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
    echo $USER | mail -s "Hello, $USER"'!' $USER
    sleep 3;
    ;;
  url)
    echo "s3+http://archivals/$hostname/home"
    ;;
  duplicity)
    shift
    duplicity "$@"
    ;;
  *)
    echo $USER | mail -s unsupported $USER
    echo unsupported ; exit 1
    ;;
esac

tidy
