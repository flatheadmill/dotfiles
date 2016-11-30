#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
    usage: dots git issue get [options] [subject]

    options:
        
        -t, --title
          display title

        -u, --url
          display url

    desciption:

    Create a GitHub issue from the command line using the given subject. If the
    creation is successful, the new issue number is printed to standard out.

    ___ . ___
*/

require('arguable')(module, require('cadence')(function (async, program) {
    var fs = require('fs')
    var ok = require('assert').ok
    var url = require('url')
    var path = require('path')
    var github = new (require('node-github'))({ version: "3.0.0" })

    async(function () {
        fs.readFile(path.join(process.env.HOME, '.dots'), 'utf8', async())
    }, function (dots) {
        dots = JSON.parse(dots)
        github.authenticate({
            type: 'oauth',
            token: dots.github.token
        });
    }, function () {
        fs.readFile('package.json', 'utf8', async())
    }, function (body) {
        var json = JSON.parse(body)
        var repository = json.repository
        ok(repository, 'repository defined')
        ok(repository.type == 'git', 'repository is git')
        var loc = url.parse(repository.url)
        ok(loc.host == 'github.com', 'repository is GitHub')
        var ident = loc.path.replace(/\..*?$/, '').split('/').slice(1)
        github.issues.getRepoIssue({
            user: ident[0], repo: ident[1], number: program.argv[0]
        }, async())
    }, function (issue) {
        if (program.ultimate.url) {
            console.log(issue.html_url)
        } else {
            console.log(issue.title)
        }
    })
}))
