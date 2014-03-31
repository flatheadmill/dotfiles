host=$(echo $SMTP_HOST | sed 's/.*\(\..*\..*\)/*\1/')

cat  <<EOF
$host:$SMTP_USERNAME:$SMTP_PASSWORD
EOF
