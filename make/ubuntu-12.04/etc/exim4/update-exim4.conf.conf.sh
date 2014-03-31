if [ -z "$SMTP_PORT" ]; then
    SMTP_PORT=587
fi

cat <<EOF
dc_eximconfig_configtype='satellite'
dc_other_hostnames=''
dc_local_interfaces='127.0.0.1'
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost='$SMTP_HOST::$SMTP_PORT'
CFILEMODE='644'
dc_use_split_config='true'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
EOF
