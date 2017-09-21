[[ ! -z "$(git ls-files --other --exclude-standard --directory)" ]] && git ls-files --other --exclude-standard --directory && echo untracked
! git diff --exit-code > /dev/null && echo uncached
! git diff --cached --exit-code > /dev/null && echo uncached
( \
 ! [ -z "$(git ls-files --other --exclude-standard --directory)" ] || \
 ! git diff --exit-code > /dev/null || \
 ! git diff --exit-code --cached > /dev/null \
) && echo dirty && exit 1

rm -rf node_modules
[[ -z "$(git diff --diff-filter=D --name-only)" ]] || git checkout node_modules
npm install
npm test
