rm -rf node_modules
npm install
if git ls-files node_modules --error-unmatch 2>/dev/null; then
    echo git checkout node_modules
    git checkout node_modules
fi
