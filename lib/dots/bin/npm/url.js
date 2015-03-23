#!/usr/bin/env node

/* 

    ___ usage: en_US ___
    usage: dots git issue create [options] [subject]

    options:
        
        -l, --label <string> @
          One or more labels to apply to the issue. 

        -m, --milestone <string>
          The milestone by number or a regular expression to match the milestone
          name.

    desciption:

    Create a GitHub issue from the command line using the given subject. If the
    creation is successful, the new issue number is printed to standard out.

    ___ usage ___
*/
        
require('arguable').parse(__filename, process.argv.slice(2), function (options) {
    var cadence = require('cadence')
    var fs = require('fs')
    var ok = require('assert').ok
    var url = require('url')
    cadence(function (step) {
        step(function () {
            fs.readFile('package.json', 'utf8', step())
        }, function (body) {
            var json = JSON.parse(body)
            var repository = json.repository
            ok(repository, 'repository defined')
            ok(repository.type == 'git', 'repository is git')
            var loc = url.parse(repository.url)
            ok(loc.host == 'github.com', 'repository is GitHub')
            var ident = loc.path.replace(/\..*?$/, '').split('/').slice(1)
            console.log('https://www.npmjs.org/package/' + ident[1])
        })
    })(options.fatal)
})

