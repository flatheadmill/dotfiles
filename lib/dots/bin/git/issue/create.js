#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
    usage: dots git issue create [options] [subject]

    options:
        
        -l, --label <string>
          One or more labels to apply to the issue. 

        -m, --milestone <string>
          The milestone by number or a regular expression to match the milestone
          name.

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
        async(function () {
            github.issues.getAllMilestones({
                user: ident[0], repo: ident[1]
            }, async())
        }, function (milestones) {
            var milestone = program.ultimate.milestone 
            if (milestone && ! /^\d+$/.test(milestone)) {
                var test = new RegExp(milestone, 'i')
                milestone = milestones.filter(function (milestone) {
                    return test.test(milestone.title)
                }).map(function (milestone) {
                    return milestone.number
                }).shift()
            }
            github.issues.create({
                user: ident[0], repo: ident[1], title: program.argv[0],
                assignee: ident[0],
                labels: [ program.ultimate.label ],
                milestone: milestone
            }, async())
        })
    }, function (response) {
        console.log(response.number)
    })
}))
