#!/bin/sh

suffix="-tmp-$$-`date +%H-%M-%S`"

trap "tidy" SIGHUP SIGINT SIGTERM

tidy () {
#  rm -f /tmp/*$suffix*
  exit $1
}

uname=`uname`
dirname=`dirname $0`

if [ "$uname-x" = "FreeBSD-x" ]; then
  . "$dirname/rc.subr"
  confdir="/usr/local/etc/postfix"
else
  confdir="/etc/postfix"
fi

# If we have no original file, create one.
if [ ! -e "$confdir/main.cf.orig" ]; then
  sudo cp "$confdir/main.cf" "$confdir/main.cf.orig"
fi

cp "$confdir/main.cf.orig" "/tmp/main$suffix.cf"

cat <<EOF >> "/tmp/main$suffix.cf"

# Relay thorugh GMail.
relayhost=smtp.gmail.com:587

smtp_sasl_auth_enable=yes
smtp_sasl_password_maps=hash:$confdir/sasl_passwd
smtp_sasl_security_options=noanonymous

smtp_use_tls=yes

smtp_tls_CAfile=/usr/local/share/certs/ca-root-nss.crt

transport_maps=hash:$confdir/transport
virtual_maps=hash:$confdir/virtual
EOF

. "$HOME/.secrets/workstation/gmail_relay"

sudo cp "/tmp/main$suffix.cf" "$confdir/main.cf"

if [ "$uname-x" = "FreeBSD-x" ]; then
  tmpconf="/tmp/rc$suffix.conf"
  cp "/etc/rc.conf" "$tmpconf"
  rc_conf_set "$tmpconf" postfix_enable YES
  sudo cp "$tmpconf" "/etc/rc.conf"
fi

cat <<EOF >> "/tmp/transport$suffix"
* smtp:[smtp.gmail.com]:587
EOF

sudo cp "/tmp/transport$suffix" "$confdir/transport"

cat <<EOF >> "/tmp/virtual$suffix"
root alan@prettyrobots.com
postmaster alan@prettyrobots.com
alan alan@prettyrobots.com
EOF

sudo cp "/tmp/virtual$suffix" "$confdir/virtual"

sudo touch "$confir/aliases"

umask 0077

cat <<EOF >> "/tmp/sasl_passwd$suffix"
[smtp.gmail.com]:587 $GMAIL_ACCOUNT:$GMAIL_PASSWD
EOF

sudo cp "/tmp/sasl_passwd$suffix" "$confdir/sasl_passwd"

sudo postmap "$confdir/sasl_passwd"
sudo postmap "$confdir/transport"
sudo postmap "$confdir/virtual"

tidy
