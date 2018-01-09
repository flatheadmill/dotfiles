#!/usr/bin/env node

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
        console.log('https://circleci.com/gh/' + ident.join('/'))
    })
}))
