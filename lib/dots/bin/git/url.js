#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
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

    ___ . ___
*/
        
require('arguable')(module, require('cadence')(function (async, options) {
    var fs = require('fs')
    var ok = require('assert').ok
    var url = require('url')
    async(function () {
        fs.readFile('package.json', 'utf8', async())
    }, function (body) {
        var json = JSON.parse(body)
        var repository = json.repository
        ok(repository, 'repository defined')
        ok(repository.type == 'git', 'repository is git')
        var loc = url.parse(repository.url)
        ok(loc.host == 'github.com', 'repository is GitHub')
        var ident = loc.path.replace(/\..*?$/, '').split('/').slice(1)
        console.log('https://github.com/' + ident.join('/'))
    })
}))
