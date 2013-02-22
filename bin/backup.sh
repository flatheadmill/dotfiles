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

duplicity_version=`duplicity --version | cut -f2 -d' '`
case $duplicity_version in
  0.6.20|0.6.18)
    break
    ;;
  *)
    abend "unsupported version $duplicity_version"
    ;;
esac

chain_end_time () {
  local collection=$1 when
  when=`duplicity collection-status s3+http://archivals/$hostname/home/$collection  \
    | grep '^Chain end time: ' | tail -n 1 | sed 's/Chain end time: //'`
  [ -z "$when" ] && echo 0 || date -j -f "%a %b %d %T %Y" "$when" "+%s"
}  

duplicity_base () {
  $HOME/.dotfiles/bin/backup.sh url
}

duplicity_exec () {
  $HOME/.dotfiles/bin/backup.sh duplicity "$@"
}

strip_listing () {
  sed -e '/.DS_Store$/d' -e '/.AppleDouble/d' -e '/^$/d'
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
      $0 backup daily \
      | tee -a "$HOME/.backups/backup.log" | mail -s "$hostname daily backup for `date`" $USER
    fi
    while read directory; do
      if $0 dirty "$directory"; then
        $0 backup "$directory" \
        | tee -a "$HOME/.backups/backup.log" | mail -s "$hostname backup of $directory for posterity on `date`" $USER
      fi
    done < "$HOME/.backups/posterity"
    ;;
  dirty)
    $0 changes $2 > /tmp/changes$suffix.txt

    if grep -q '^D' /tmp/changes$suffix.txt; then
      tidy 0
    else
      sed -e 's/^A //' /tmp/changes$suffix.txt > /tmp/additions$suffix.txt
      $0 listing $2 > /tmp/existing$suffix.txt
      diff /tmp/existing$suffix.txt /tmp/additions$suffix.txt | grep -q '^>' && tidy 0 || tidy 1
    fi
    ;;
  stage)
    volume="$2" stage="$3"; shift; shift; shift
    duplicity -v8 \
        --exclude-globbing-filelist "$HOME/.backups/exclude" \
        --include "$HOME/$volume" \
        --gpg-options="--compress-algo=bzip2 --bzip2-compress-level=9" \
        --exclude "**" \
        "$@" \
        "$HOME" "file://$stage/$volume"
    ;;
  backup)
    volume="$2"
    if [ "$volume" = "full" ]; then
      full="full"
      volume="$3"
      shift;
    fi
    shift; shift
    if [ -e "$HOME/.backups.running" ]; then
      abend "backup is already running"
    fi
    touch "$HOME/.backups/running"
    if [ "$volume" = "daily" ]; then
      duplicity $full -v8 \
            --allow-source-mismatch \
            --exclude-globbing-filelist "$HOME/.backups/exclude" \
            --include-globbing-filelist "$HOME/.backups/daily" \
            --exclude "**" \
            "$@" \
            "$HOME" "s3+http://archivals/$hostname/home/$volume"
    else
      duplicity $full -v8 \
          --allow-source-mismatch \
          --exclude-globbing-filelist "$HOME/.backups/exclude" \
          --include "$HOME/$volume" \
          --exclude "**" \
          "$@" \
          "$HOME" "s3+http://archivals/$hostname/home/$volume"
    fi
    rm "$HOME/.backups/running"
    ;;
  listing)
    duplicity_exec list-current-files `duplicity_base`/$2 | \
      tail -n +3 | \
      sed 's/[A-Za-z]\{3\} [A-Za-z]\{3\} \{1,2\}[0-9]\{1,2\} \([0-9]\{2\}:\)\{2\}[0-9]\{2\} [0-9]\{4\} //' | \
      sort
    ;;
  files)
    duplicity_exec list-current-files `duplicity_base`/$2
    ;;
  changes)
    $0 backup "$2" --dry-run | grep '^[AD] ' | sort -k 2
    ;;
  dry-run)
    $0 backup "$2" --dry-run
    ;;
  verify)
    volume="$2"
    if [ "$volume" = "daily" ]; then
      duplicity verify -v8 \
        --exclude-globbing-filelist "$HOME/.backups/exclude" \
        --include-globbing-filelist "$HOME/.backups/daily" \
        --exclude "**" \
        `~/.dotfiles/bin/backup.sh url`/"$volume" "$HOME"
    else
      duplicity_exec verify -v8 \
        --exclude-globbing-filelist "$HOME/.backups/exclude" \
        --include "$HOME/$volume" \
        --exclude "**" \
        `~/.dotfiles/bin/backup.sh url`/"$volume" "$HOME"
    fi
    ;;
  status)
    duplicity collection-status "s3+http://archivals/$hostname/home/$2"
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
