#!/usr/bin/env node


var path = require('path')
var directory = process.argv[2] || '.'
var pkg = require(path.resolve(directory, 'package.json'))

var version = pkg.version.split('.').map(function (part) { return  +part })

if (version[0] == 0) {
    process.stdout.write('latest\n')
} else if (version[0] % 2 == 1) {
    if (version[1] % 2 == 1) {
        process.stdout.write('dev\n')
    } else {
        process.stdout.write('latest\n')
    }
} else {
    process.stdout.write('canary\n')
}
