#!/bin/sh

set -e

if ! which istanbul > /dev/null; then
    cat << EOF 1>&2

Istanbul is required to run coverage. Install Istanbul:

    npm install -g istanbul

EOF
    exit 1
fi

rm -rf coverage

count=1;
for file in $(find . ! -path '*/node_modules/*' -name \*.t.js); do
  istanbul cover -x 't/**' -x '*/t/**' $file > /dev/null 2>&1
  mv coverage/coverage.json coverage/coverage$count.json
  count=$(expr $count + 1)
done

istanbul report --root coverage --dir coverage > /dev/null

sed -i -e s,'^SF:'`pwd`/,SF:, coverage/lcov.info

exit 0
