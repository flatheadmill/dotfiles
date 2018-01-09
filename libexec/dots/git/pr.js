#!/usr/bin/env node

/* 

    ___ usage ___ en_US ___
    usage: dots git pr <branch> <number>

    options:

    Checkout a Pull Request on a branch with the given name.

    ___ . ___
*/
        
require('arguable')(module, require('cadence')(function (async, program) {
    var fs = require('fs')
    var ok = require('assert').ok
    var url = require('url')
    var path = require('path')
    var github = new (require('node-github'))({ version: "3.0.0" })
    var branch = program.argv[0]
    var number = program.argv[1]
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
            github.pullRequests.get({
                user: ident[0], repo: ident[1], number: number
            }, async())
        }, function (pr) {
            console.log('git checkout -b ' + branch + ' ' + pr.base.sha)
            console.log('git pull ' + pr.head.repo.clone_url + ' ' + pr.head.ref)
        })
    })
}))
