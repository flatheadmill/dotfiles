#!/bin/sh

suffix="-tmp-$$-`date +%H-%M-%S`"

trap "tidy" SIGHUP SIGINT SIGTERM

tidy () {
  rm -f /tmp/*$suffix*
  exit $1
}

uname=`uname`
hostname=`hostname`
ip=`ifconfig | grep 'inet 192.168' | sed 's/.*inet \(192.168[^ ]*\).*/\1/'`

if [ "$uname-x" = "FreeBSD-x" ]; then
  confdir="/usr/local/etc"
else
  confdir="/etc/netatalk"
fi

cat <<EOF > "/tmp/afpd$suffix.conf"
# $confdir/afpd.conf
#
# Again, see /usr/local/etc/afpd.conf.dist for more info.
# This file has a single line.

- -tcp -noddp -uamlist uams_dhx.so,uams_dhx2.so -setuplog "default log_info" -cnidserver 127.0.0.1:4700 -ipaddr $ip

# EOF
EOF

sudo cp "/tmp/afpd$suffix.conf" "$confdir/afpd.conf"

cat <<EOF > "/tmp/AppleVolumes$suffix.default"
# $confdir/AppleVolumes.default

:DEFAULT: options:upriv,usedots

$HOME $hostname allow:alan options:usedots,upriv

# EOF
EOF

sudo cp "/tmp/AppleVolumes$suffix.default" "$confdir/AppleVolumes.default"

cat <<EOF > "/tmp/netatalk$suffix.conf"
# $confdir/netatalk.conf
#
# See /usr/local/etc/netatalk.conf.dist for more info.

AFPD_MAX_CLIENTS=20
ATALK_NAME=$hostname
ATALK_MAC_CHARSET='MAC_ROMAN'
ATALK_UNIX_CHARSET='LOCALE'
AFPD_GUEST=nobody
CNID_CONFIG="-l log_note"

# EOF
EOF

sudo cp "/tmp/netatalk$suffix.conf" "$confdir/netatalk.conf"

rc_conf_set () {
  local conf=$1 key=$2 value=$3 cur
  (
    . "$conf"
    eval cur=\$${key}
    if [ "${cur}-x" != "${value}-x" ]; then
      if [ "${cur}-x" != "-x" ]; then
        sed -i -e '/'${key}'=/d' "$tmpconf"
      fi
      echo ${key}'="'${value}'"' >> "$tmpconf"
    fi
  )
}

if [ "$uname-x" = "FreeBSD-x" ]; then
  tmpconf="/tmp/rc$suffix.conf"
  cp "/etc/rc.conf" "$tmpconf"
  rc_conf_set "$tmpconf" afpd_enable YES
  rc_conf_set "$tmpconf" atalkd_enable NO
  rc_conf_set "$tmpconf" cnid_metad_enable YES
  rc_conf_set "$tmpconf" netatalk_enable YES
  sudo cp "$tmpconf" "/etc/rc.conf"
fi

tidy
