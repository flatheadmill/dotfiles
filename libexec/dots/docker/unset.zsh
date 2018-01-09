#!/usr/bin/env zsh

source $dots <<- usage
  usage: dots docker unset

  desctiption:

    Unset Docker Machine environment variables.
usage

cat <<EOF
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH
unset DOCKER_MACHINE_NAME
unset DOCKER_HOST
EOF
