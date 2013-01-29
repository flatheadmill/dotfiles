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
  directory=$1
  duplicity_exec list-current-files `duplicity_base`/$directory | \
    tail -n +3 | \
    sed 's/[A-Za-z]\{3\} [A-Za-z]\{3\} \{1,2\}[0-9]\{1,2\} \([0-9]\{2\}:\)\{2\}[0-9]\{2\} [0-9]\{4\} //' > /tmp/duplicity_listing$suffix.txt
  # Assert that we correctly stripped the date out of the Duplicity listing.
  # Note the use of the UNIX path separator as a regex operator for sed.
  start=`echo "$directory" | grep -o / | wc -l`
  start=`expr 2 + $start`
  lines=`tail -n +$start /tmp/duplicity_listing$suffix.txt | sed '\:^'$directory':d' | wc -l`
  [ $lines -eq 0 ] || abend "could not strip dates from Duplicity listing: $lines"
  length=`expr ${#directory} + 2`
  cut -c $length- /tmp/duplicity_listing$suffix.txt | strip_listing | sort
}

strip_listing () {
  sed -e '/.DS_Store$/d' -e '/.AppleDouble/d' -e '/^$/d'
}

directory_changes () {
  volume="$1"

  $0 changes > /tmp/changes$suffix.txt
  lines=`sed -e 's/^[AD] //' /tmp/changes$suffix.txt | sed '\:^'$directory':d' | wc -l`

  echo $lines

}

directory_has_addtions () {
  volume=$1

  $0 changes $volume | strip_listing > /tmp/changes$suffix.txt

  if grep '^D' /tmp/changes$suffix.txt; then
    return 0
  else
    sed -e 's/^A //' /tmp/changes$suffix.txt > /tmp/additions$suffix.txt
    duplicity_listing $volume | strip_listing > /tmp/existing$suffix.txt
    diff /tmp/existing$suffix.txt /tmp/additions$suffix.txt | grep -q '^>'
  fi
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
      $0 backup daily
    fi
    while read directory; do
      if directory_has_addtions "$directory"; then
        $0 backup "$directory"
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
  backup)
    volume="$2"
    if [ "$volume" = "full" ]; then
      full="full"
      volume="$3"
    fi
    shift; shift
    if [ -e "$HOME/.backups.running" ]; then
      abend "backup is already running"
    fi
    touch "$HOME/.backups/running"
    if [ "$volume" = "daily" ]; then
      duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
            --include-globbing-filelist "$HOME/.backups/daily" \
            --exclude "**" \
            "$@" \
            "$HOME" "s3+http://archivals/$hostname/home/$volume"
    else
      duplicity $full -v8 --exclude-regexp '[.](AppleDouble|DS_Store)' \
          --exclude-globbing-filelist "$HOME/.backups/exclude" \
          --include "$HOME/$volume" \
          --exclude "**" \
          "$@" \
          "$HOME" "s3+http://archivals/$hostname/home/$volume"
    fi
    rm "$HOME/.backups/running"
    ;;
  listing)
    duplicity_listing $2
    ;;
  changes)
    volume="$2"
    $0 backup "$volume" --dry-run | grep '^[AD] ' | sort -k 2 > /tmp/changes$suffix.txt
    start=`echo "$volume" | grep -o / | wc -l`
    start=`expr 3 + $start`
    lines=`tail -n +$start /tmp/changes$suffix.txt | sed -e '\:^[AD] '$volume':d' | wc -l`
    [ $lines -eq 0 ] || abend "unexepected Duplicity listing: $lines"
    tail -n +$start /tmp/changes$suffix.txt | sed -e 's:^\([AD]\) '$volume'/:\1 :'
    ;;
  dry-run)
    $0 backup "$2" --dry-run
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
