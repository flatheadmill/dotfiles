cat  <<EOF
Protocol 2
AcceptEnv LANG LC_*
UsePAM yes
ChallengeResponseAuthentication no
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
PrintMotd no
EOF
