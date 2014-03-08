#!/usr/bin/env node

/* 

    ___ usage: en_US ___
    usage: dots git issue list

    desciption:

    Get a list GitHub Issues for the current project.

    ___ usage ___
*/

require('arguable').parse(__filename, process.argv.slice(2), function (options) {
    var path = require('path')
    var url = require('url')
    var fs = require('fs')
    var ok = require('assert').ok
    var github = new (require('node-github'))({ version: "3.0.0" })
    var cadence = require('cadence')
    cadence(function (step) {
        step(function () {
            fs.readFile(path.join(process.env.HOME, '.dots'), 'utf8', step())
        }, function (dots) {
            dots = JSON.parse(dots)
            github.authenticate({
                type: "basic",
                username: dots.github.user,
                password: dots.github.password
            });
        }, function () {
            fs.readFile('package.json', 'utf8', step())
        }, function (body) {
            var json = JSON.parse(body)
            var repository = json.repository
            ok(repository, 'repository defined')
            ok(repository.type == 'git', 'repository is git')
            var loc = url.parse(repository.url)
            ok(loc.host == 'github.com', 'repository is GitHub')
            var ident = loc.path.replace(/\..*?$/, '').split('/').slice(1)
            step(function () {
                github.issues.repoIssues({
                    user: ident[0], repo: ident[1], milestone: '*', assignee: '*'
                }, step())
            }, function (issues) {
                issues.forEach(function (issue) {
                    console.log(issue.title, '#' + issue.number + '.')
                })
            })
        })
    })(options.fatal)
})
