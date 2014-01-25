#!/usr/bin/env node

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
        github.issues.getRepoIssue({
            user: ident[0], repo: ident[1], number: process.argv[2]
        }, step())
    }, function (response) {
        console.log(response.title)
    })
})(function (error) { if (error) throw error })
