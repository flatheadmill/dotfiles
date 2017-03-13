#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
    usage: dots git issue create [options] [subject]

    desciption:

    Create a GitHub issue from the command line using the given subject. If the
    creation is successful, the new issue number is printed to standard out.

    ___ . ___
*/
// TODO Really should be `dots node package --travis` or something.
require('arguable')(module, require('cadence')(function (async, program) {
    var fs = require('fs')
    var ok = require('assert').ok
    var url = require('url')
    async(function () {
        fs.readFile('package.json', 'utf8', async())
    }, function (body) {
        var json = JSON.parse(body)
        program.stdout.write('https://www.npmjs.com/package/' + json.name + '\n')
    })
}))
