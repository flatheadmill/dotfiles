#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
    usage: dots git issue list

    desciption:

    Get a list GitHub Issues for the current project.

    ___ . ___
*/

require('arguable')(module, require('cadence')(function (async, program) {
    var path = require('path')
    var url = require('url')
    var fs = require('fs')
    var ok = require('assert').ok
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
        async(function () {
            github.issues.repoIssues({
                user: ident[0], repo: ident[1], milestone: '*', assignee: '*'
            }, async())
        }, function (issues) {
            issues.forEach(function (issue) {
                console.log(issue.title, '#' + issue.number + '.')
            })
        })
    })
}))
