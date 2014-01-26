#!/usr/bin/env node

var fs = require('fs')
var config = JSON.parse(fs.readFileSync('package.json', 'utf8'))

for (var key in config.dependencies) {
    console.log(key)
}
