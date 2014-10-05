#!/usr/bin/env node

var fs = require('fs')
var config = JSON.parse(fs.readFileSync('package.json', 'utf8'))

console.log(config.version)
