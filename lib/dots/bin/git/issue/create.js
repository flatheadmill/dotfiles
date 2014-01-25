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
    var fs = require('fs')
    var cadence = require('cadence')
    var ok = require('assert').ok
    var url = require('url')
    var path = require('path')
    var github = new (require('node-github'))({ version: "3.0.0" })
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
                github.issues.getAllMilestones({
                    user: ident[0], repo: ident[1]
                }, step())
            }, function (milestones) {
                var milestone = options.params.milestone 
                if (milestone && ! /^\d+$/.test(milestone)) {
                    var test = new RegExp(milestone, 'i')
                    milestone = milestones.filter(function (milestone) {
                        return test.test(milestone.title)
                    }).map(function (milestone) {
                        return milestone.number
                    }).shift()
                }
                github.issues.create({
                    user: ident[0], repo: ident[1], title: options.argv[0],
                    assignee: ident[0],
                    labels: options.params.label,
                    milestone: milestone
                }, step())
            })
        }, function (response) {
            console.log(response.number)
        })
    })(options.fatal)
})
