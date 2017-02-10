#!/usr/bin/env node

require('arguable')(module, require('cadence')(function (async, program) {
    var delta = require('delta')
    var semver = require('semver')
    program.stdin.resume()
    async(function () {
        delta(async()).ee(program.stdin).on('data', []).on('end')
    }, function (stdin) {
        var json = JSON.parse(Buffer.concat(stdin).toString())
        program.stdout.write(json.versions.sort(semver.compare).pop() + '\n')
    })
}))
